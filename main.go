package main

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/jvzantvoort/fortune/content"
)

func main() {
	rand.Seed(time.Now().Unix())

	files, _ := content.GetFortuneFiles()
	filename := files[rand.Intn(len(files))]

	rows := content.ReadFortune(filename)
	retv := rows[rand.Intn(len(rows))]
	fmt.Printf("%s\n", retv)

}
