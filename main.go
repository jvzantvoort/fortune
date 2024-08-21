package main

import (
	"flag"
	"fmt"
	"math/rand"
	"strings"

	"github.com/jvzantvoort/fortune/content"
)

var (
	listFiles bool
	showFile  bool
)

func init() {
	flag.BoolVar(&listFiles, "f", false, "Print out the list of files which would be searched, but don't print a fortune.")
	flag.BoolVar(&showFile, "c", false, "Show the cookie file from which the fortune came.")

}

func main() {
	flag.Parse()

	files, _ := content.GetFortuneFiles()
	if listFiles {
		for _, target := range files {
			fmt.Printf("- %s\n", strings.Replace(target, ".fortune", "", -1))
		}
		return
	}
	filename := files[rand.Intn(len(files))]

	if showFile {
		fmt.Printf("\nsource: %s\n\n", filename)
	}

	rows := content.ReadFortune(filename)
	retv := rows[rand.Intn(len(rows))]
	fmt.Printf("%s\n", retv)

}

/*
   -a

       Choose from all lists of maxims, both offensive and not. (See the -o option for more information on offensive fortunes.)

   -e

       Consider all fortune files to be of equal size (see discussion below on multiple files).


   -l

       Long dictums only. See -n on how “long” is defined in this sense.


   -m pattern

       Print out all fortunes which match the basic regular expression pattern. The syntax of these expressions depends on how your system defines re_comp(3) or regcomp(3), but it should nevertheless be similar to the
       syntax used in grep(1).

       The fortunes are output to standard output, while the names of the file from which each fortune comes are printed to standard error. Either or both can be redirected; if standard output is redirected to a file, the
       result is a valid fortunes database file. If standard error is also redirected to this file, the result is still valid, but there will be “bogus” fortunes, i.e. the filenames themselves, in parentheses. This can be
       useful if you wish to remove the gathered matches from their original files, since each filename-record will precede the records from the file it names.

   -n length

       Set the longest fortune length (in characters) considered to be “short” (the default is 160). All fortunes longer than this are considered “long”. Be careful! If you set the length too short and ask for short
       fortunes, or too long and ask for long ones, fortune goes into a never-ending thrash loop.

   -o Choose only from potentially offensive aphorisms. The -o option is ignored if a fortune directory is specified.

       Please, please, please request a potentially offensive fortune if and only if you believe, deep in your heart, that you are willing to be offended. (And that you'll just quit using -o rather than give us grief about
       it, okay?)

       ... let us keep in mind the basic governing philosophy of The Brotherhood, as handsomely summarized in these words: we believe in healthy, hearty laughter -- at the expense of the whole human race, if needs be. Needs
       be.

       --H. Allen Smith, "Rude Jokes"

   -s

       Short apothegms only. See -n on which fortunes are considered “short”.

   -i

       Ignore case for -m patterns.

   -w

       Wait before termination for an amount of time calculated from the number of characters in the message. This is useful if it is executed as part of the logout procedure to guarantee that the message can be read before
       the screen is cleared.


*/
