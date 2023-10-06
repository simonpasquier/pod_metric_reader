package main

import (
	"context"
	"flag"
	"fmt"
	"sync"
	"time"

	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/metrics/pkg/client/clientset/versioned"
)

func main() {
	nb := flag.Uint64("concurrency", 16, "number of concurrent clients")
	flag.Parse()

	cfg, err := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(
		clientcmd.NewDefaultClientConfigLoadingRules(),
		&clientcmd.ConfigOverrides{},
	).ClientConfig()
	if err != nil {
		panic(err)
	}

	cs, err := versioned.NewForConfig(cfg)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Starting %d threads\n", *nb)
	var (
		wg sync.WaitGroup
		i  uint64
	)
	for i = 0; i < *nb; i++ {
		wg.Add(1)
		go func(i uint64) {
			defer wg.Done()

			var (
				cnt int64
				sum time.Duration
				max time.Duration
			)
			for {
				now := time.Now()
				mc := cs.MetricsV1beta1().PodMetricses("")
				_, err = mc.List(context.Background(), v1.ListOptions{})
				if err != nil {
					fmt.Printf("thread %d: err: %s\n", i, err)
				}
				cnt++
				dur := time.Since(now)
				sum += dur
				if dur > max {
					max = dur
				}
				if cnt%10 == 0 {
					fmt.Printf("thread %d (last 10 calls): avg: %s, max: %s\n", i, time.Duration(int64(sum)/cnt), max)
					sum, max, cnt = 0, 0, 0
				}
			}
		}(i)
	}

	wg.Wait()
}
