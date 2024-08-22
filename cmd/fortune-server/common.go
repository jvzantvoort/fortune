package main

import (
	"math/rand"

	"github.com/jvzantvoort/fortune/content"
)

func GetFortune() string {

	files, _ := content.GetFortuneFiles()
	filename := files[rand.Intn(len(files))]

	rows := content.ReadFortune(filename)
	retv := rows[rand.Intn(len(rows))]
	return retv + "\n"
}
