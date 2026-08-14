package main

import (
	"flag"
	"fmt"
	"io"
	"os"
)

var version = "dev"

func run(args []string, stdout, stderr io.Writer) int {
	flags := flag.NewFlagSet("hello-tool", flag.ContinueOnError)
	flags.SetOutput(stderr)
	name := flags.String("name", "world", "name to greet")
	showVersion := flags.Bool("version", false, "print version and exit")
	flags.Usage = func() {
		fmt.Fprintln(stderr, "Usage: hello-tool [-name NAME] [-version]")
		flags.PrintDefaults()
	}

	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintf(stderr, "unexpected argument: %s\n", flags.Arg(0))
		flags.Usage()
		return 2
	}
	if *showVersion {
		fmt.Fprintln(stdout, version)
		return 0
	}

	fmt.Fprintf(stdout, "Hello, %s!\n", *name)
	return 0
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}
