package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/chromedp/chromedp"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	target := flag.String("target","", "url target to reload")
	user := flag.String("user","", "")
	pass := flag.String("pass","", "")
	flag.Parse()

	if *target == "" || *user == "" || *pass == "" {
		fmt.Println("flags are required")
		os.Exit(1)
	}

	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.Flag("headless", false),
		chromedp.Flag("disable-gpu", false),
		chromedp.Flag("enable-automation", false),
		chromedp.Flag("disable-extensions", false),
	)

	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	// create chrome instance
	ctx, cancel := chromedp.NewContext(
		allocCtx,
		chromedp.WithLogf(log.Printf),
	)
	defer cancel()

	err := chromedp.Run(ctx,
		chromedp.Navigate(*target),
		chromedp.WaitVisible(`//input[@name="user"]`),
		chromedp.SendKeys(`//input[@name="user"]`, *user),
		chromedp.SendKeys(`//input[@name="password"]`, *pass),
		chromedp.Click(`//button[contains(., 'Log')]`, chromedp.NodeVisible),
	)
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println("chrome reloader starting")

	var server *http.Server
	router := mux.NewRouter()
	router.HandleFunc("/reload", func(w http.ResponseWriter, req *http.Request) {
		fmt.Println("reload")
		if err := chromedp.Run(ctx,
			chromedp.Reload(),
		); err != nil {
			fmt.Println(err)
		}
	})
	router.HandleFunc("/shutdown", func(w http.ResponseWriter, req *http.Request) {
		fmt.Println("shutdown")
		w.WriteHeader(200)
		go func(){
			time.Sleep(1 * time.Second)
			server.Close()
		}()
	})

	server = &http.Server{
		Addr:    "127.0.0.1:8686",
		Handler: router,
	}
	server.ListenAndServe()
}
