# Reality Permit

`reality-permit` is a dependency-free Perl 5.38 command-line bureaucracy that decides whether procedurally generated universes are legally permitted to exist. Every seed produces the same applicants, allegations, remedies, measurements, and rulings, making the Ministry arbitrary but reproducible.

```bash
chmod +x reality-permit.pl
./reality-permit.pl --seed 1982
./reality-permit.pl --seed 1982 --count 7 --appeal
prove -v t
```

The program uses only Perl core modules. It does not read files, access the network, invoke subprocesses, or modify the environment. Its authority is therefore entirely imaginary.
