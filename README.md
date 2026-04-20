# RTOP

A terminal-based system monitor for Linux, inspired by [atop](https://www.atoptool.nl/). Built in Rust using [ratatui](https://github.com/ratatui/ratatui) and [sysinfo](https://github.com/GuillaumeGomez/sysinfo).

## Features

- **CPU panel** – global usage gauge + per-core gauges (up to 6 cores shown)
- **Memory / Swap panel** – bar gauges with human-readable sizes
- **Network panel** – per-interface RX / TX byte counters
- **Process table** – PID, CPU%, resident memory, virtual memory, status, user, name, and full command line
- **Sorting** – sort by CPU%, memory, PID, or process name
- **Scrolling** – scroll the process list with arrow keys or vim-style `j`/`k`
- **Auto-refresh** – data refreshes every 2 seconds

## Key Bindings

| Key | Action |
|-----|--------|
| `q` / `Ctrl-C` | Quit |
| `c` | Sort by CPU% (default) |
| `m` | Sort by memory |
| `p` | Sort by PID |
| `n` | Sort by name |
| `↑` / `k` | Scroll up |
| `↓` / `j` | Scroll down |

## Build & Run

```bash
cargo build --release
./target/release/rtop
```

Or run directly:

```bash
cargo run --release
```
