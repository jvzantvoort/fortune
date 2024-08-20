package content

import (
	"embed"
	"fmt"
	"io/fs"
	"path/filepath"
	"strings"
)

//go:embed fortunes/*
var Content embed.FS

func GetContent(name string) string {
	filename := fmt.Sprintf("fortunes/%s", name)

	msgstr, err := Content.ReadFile(filename)
	if err != nil {
		panic(err)
		// msgstr = []byte("")
	}
	return strings.TrimSuffix(string(msgstr), "\n")

}

func GetFortuneFiles() ([]string, error) {
	fortuneFiles := []string{}

	files, err := fs.ReadDir(Content, "fortunes")
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if filepath.Ext(file.Name()) == ".fortune" {
			fortuneFiles = append(fortuneFiles, file.Name())
		}
	}

	return fortuneFiles, nil
}

func ReadFortune(name string) []string {
	content := GetContent(name)
	buffer := []string{}
	retv := []string{}

	for _, line := range strings.Split(content, "\n") {
		if line == "%" {
			if len(buffer) != 0 {
				retv = append(retv, strings.Join(buffer, "\n"))
				buffer = nil
			}
		} else {
			buffer = append(buffer, line)
		}
	}
	if len(buffer) != 0 {
		retv = append(retv, strings.Join(buffer, "\n"))
		buffer = nil
	}
	return retv
}
