use std::collections::BTreeSet;
use std::env;
use std::fmt::Write as _;

const SUBJECTS: &[&str] = &[
    "the moon", "Tuesday", "a municipal ghost", "the final cauliflower",
    "gravity", "the Ministry of Puddles", "an unauthorized oracle", "history itself",
];

const VERBS: &[&str] = &[
    "patented", "misplaced", "recalled", "folded", "nationalized", "dreamed",
    "recompiled", "quietly replaced",
];

const OBJECTS: &[&str] = &[
    "the year 1982", "three ornamental dimensions", "a backup sun", "everyone's alibi",
    "the color after violet", "a legally distinct apocalypse", "yesterday's trousers",
    "the original version of the future",
];

#[derive(Clone, Debug, Eq, PartialEq)]
struct Event {
    year: i32,
    subject: &'static str,
    verb: &'static str,
    object: &'static str,
    hash: u64,
}

impl Event {
    fn sentence(&self) -> String {
        format!("{} {} {}", self.subject, self.verb, self.object)
    }
}

#[derive(Clone, Debug)]
struct Commit {
    id: u64,
    parent: Option<u64>,
    event: Event,
    accepted: bool,
    reason: String,
}

#[derive(Clone, Debug)]
struct Rng(u64);

impl Rng {
    fn new(seed: u64) -> Self {
        Self(seed.max(1))
    }

    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }

    fn choose<'a>(&mut self, values: &'a [&'a str]) -> &'a str {
        values[self.next() as usize % values.len()]
    }
}

struct Universe {
    seed: u64,
    commits: Vec<Commit>,
    occupied_years: BTreeSet<i32>,
    head: Option<u64>,
}

impl Universe {
    fn new(seed: u64) -> Self {
        Self { seed, commits: Vec::new(), occupied_years: BTreeSet::new(), head: None }
    }

    fn commit(&mut self, event: Event) {
        let id = mix(event.hash ^ self.seed ^ self.commits.len() as u64);
        let duplicate_year = self.occupied_years.contains(&event.year);
        let self_erasing = event.subject == "history itself" && event.verb == "quietly replaced";
        let apocalypse_without_alibi = event.object == "a legally distinct apocalypse"
            && !self.commits.iter().any(|c| c.accepted && c.event.object == "everyone's alibi");

        let (accepted, reason) = if duplicate_year {
            (false, "year already occupied by a more senior absurdity".to_owned())
        } else if self_erasing {
            (false, "commit would erase the committee reviewing the commit".to_owned())
        } else if apocalypse_without_alibi {
            (false, "apocalypse lacks an admissible alibi".to_owned())
        } else {
            (true, "causality reluctantly permits this".to_owned())
        };

        let parent = self.head;
        if accepted {
            self.occupied_years.insert(event.year);
            self.head = Some(id);
        }
        self.commits.push(Commit { id, parent, event, accepted, reason });
    }

    fn log(&self) -> String {
        let mut out = String::new();
        writeln!(out, "COUNTERFACTUAL GIT — REPOSITORY OF IMPROPER HISTORY").unwrap();
        writeln!(out, "universe seed: {}", self.seed).unwrap();
        writeln!(out, "HEAD: {}\n", self.head.map(short_hash).unwrap_or_else(|| "VOID".into())).unwrap();

        for commit in self.commits.iter().rev() {
            let mark = if commit.accepted { "COMMIT" } else { "REJECT" };
            writeln!(out, "{} {}", mark, short_hash(commit.id)).unwrap();
            writeln!(out, "  parent: {}", commit.parent.map(short_hash).unwrap_or_else(|| "VOID".into())).unwrap();
            writeln!(out, "  date:   {} CE (approximately)", commit.event.year).unwrap();
            writeln!(out, "  event:  {}.", commit.event.sentence()).unwrap();
            writeln!(out, "  ruling: {}\n", commit.reason).unwrap();
        }

        let accepted = self.commits.iter().filter(|c| c.accepted).count();
        let rejected = self.commits.len() - accepted;
        writeln!(out, "{} historical events survived; {} were returned to speculation.", accepted, rejected).unwrap();
        out
    }
}

fn mix(mut x: u64) -> u64 {
    x ^= x >> 30;
    x = x.wrapping_mul(0xbf58_476d_1ce4_e5b9);
    x ^= x >> 27;
    x = x.wrapping_mul(0x94d0_49bb_1331_11eb);
    x ^ (x >> 31)
}

fn short_hash(hash: u64) -> String {
    format!("{:08x}", hash as u32)
}

fn generate(seed: u64, count: usize) -> Universe {
    let mut rng = Rng::new(seed);
    let mut universe = Universe::new(seed);
    for index in 0..count {
        let year = 1600 + (rng.next() % 601) as i32;
        let subject = rng.choose(SUBJECTS);
        let verb = rng.choose(VERBS);
        let object = rng.choose(OBJECTS);
        let hash = mix(seed ^ index as u64 ^ rng.next());
        universe.commit(Event { year, subject, verb, object, hash });
    }
    universe
}

fn usage() {
    println!("counterfactual-git [--seed NUMBER] [--events 1..100]\n\nVersion control for histories that should never have existed.");
}

fn parse_args() -> Result<(u64, usize), String> {
    let mut seed = 1982_u64;
    let mut events = 12_usize;
    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--seed" => {
                seed = args.next().ok_or("--seed needs a value")?
                    .parse().map_err(|_| "--seed must be an unsigned integer")?;
            }
            "--events" => {
                events = args.next().ok_or("--events needs a value")?
                    .parse().map_err(|_| "--events must be an integer")?;
                if !(1..=100).contains(&events) { return Err("--events must be between 1 and 100".into()); }
            }
            "--help" | "-h" => { usage(); std::process::exit(0); }
            other => return Err(format!("unknown argument: {other}")),
        }
    }
    Ok((seed, events))
}

fn main() {
    match parse_args() {
        Ok((seed, events)) => print!("{}", generate(seed, events).log()),
        Err(error) => { eprintln!("error: {error}\n"); usage(); std::process::exit(2); }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generation_is_deterministic() {
        assert_eq!(generate(1982, 12).log(), generate(1982, 12).log());
    }

    #[test]
    fn conflicting_year_is_rejected() {
        let event = Event { year: 1982, subject: "the moon", verb: "folded", object: "Tuesday", hash: 1 };
        let mut universe = Universe::new(7);
        universe.commit(event.clone());
        universe.commit(Event { hash: 2, ..event });
        assert!(universe.commits[0].accepted);
        assert!(!universe.commits[1].accepted);
    }

    #[test]
    fn dangerous_apocalypse_needs_an_alibi() {
        let mut universe = Universe::new(7);
        universe.commit(Event {
            year: 2001, subject: "Tuesday", verb: "patented",
            object: "a legally distinct apocalypse", hash: 3,
        });
        assert!(!universe.commits[0].accepted);
    }
}
