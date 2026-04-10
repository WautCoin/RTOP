use human_bytes::human_bytes;
use ratatui::{
    Frame,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Cell, Gauge, Paragraph, Row, Table, TableState},
};

use crate::app::{App, SortBy};

pub fn draw(f: &mut Frame, app: &App) {
    let area = f.area();

    // Top-level layout: header | process table | footer
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(9),  // system stats header
            Constraint::Min(5),     // process table
            Constraint::Length(1),  // key hints footer
        ])
        .split(area);

    draw_header(f, app, chunks[0]);
    draw_processes(f, app, chunks[1]);
    draw_footer(f, chunks[2]);
}

fn draw_header(f: &mut Frame, app: &App, area: Rect) {
    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    draw_cpu_section(f, app, cols[0]);
    draw_mem_section(f, app, cols[1]);
}

fn draw_cpu_section(f: &mut Frame, app: &App, area: Rect) {
    let block = Block::default()
        .title(" CPU ")
        .borders(Borders::ALL)
        .style(Style::default().fg(Color::Cyan));

    let inner = block.inner(area);
    f.render_widget(block, area);

    // Split inner area: global gauge on top, then per-core rows
    let num_cores = app.cpu.core_usages.len().min(6);
    let mut constraints = vec![Constraint::Length(2)]; // global
    for _ in 0..num_cores {
        constraints.push(Constraint::Length(1));
    }

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints(constraints)
        .split(inner);

    // Global CPU gauge
    let gauge = Gauge::default()
        .label(format!("{:.1}%", app.cpu.global_usage))
        .ratio(app.cpu.global_usage as f64 / 100.0)
        .gauge_style(Style::default().fg(Color::Green).bg(Color::DarkGray));
    f.render_widget(gauge, rows[0]);

    // Per-core gauges
    for (i, &usage) in app.cpu.core_usages.iter().take(num_cores).enumerate() {
        let label = format!("#{:<2} {:>5.1}%", i, usage);
        let gauge = Gauge::default()
            .label(label.clone())
            .ratio((usage as f64 / 100.0).clamp(0.0, 1.0))
            .gauge_style(Style::default().fg(Color::LightGreen).bg(Color::DarkGray));
        f.render_widget(gauge, rows[i + 1]);
    }
}

fn draw_mem_section(f: &mut Frame, app: &App, area: Rect) {
    let block = Block::default()
        .title(" MEM / SWAP / NET ")
        .borders(Borders::ALL)
        .style(Style::default().fg(Color::Cyan));

    let inner = block.inner(area);
    f.render_widget(block, area);

    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Length(2),
            Constraint::Min(1),
        ])
        .split(inner);

    // Memory gauge
    let mem_pct = if app.mem.total > 0 {
        app.mem.used as f64 / app.mem.total as f64
    } else {
        0.0
    };
    let mem_label = format!(
        "{} / {}",
        human_bytes(app.mem.used as f64),
        human_bytes(app.mem.total as f64)
    );
    let mem_gauge = Gauge::default()
        .label(mem_label)
        .ratio(mem_pct.clamp(0.0, 1.0))
        .gauge_style(Style::default().fg(Color::Yellow).bg(Color::DarkGray));
    f.render_widget(mem_gauge, rows[0]);

    // Swap gauge
    let swap_pct = if app.mem.swap_total > 0 {
        app.mem.swap_used as f64 / app.mem.swap_total as f64
    } else {
        0.0
    };
    let swap_label = format!(
        "SWP {} / {}",
        human_bytes(app.mem.swap_used as f64),
        human_bytes(app.mem.swap_total as f64)
    );
    let swap_gauge = Gauge::default()
        .label(swap_label)
        .ratio(swap_pct.clamp(0.0, 1.0))
        .gauge_style(Style::default().fg(Color::Magenta).bg(Color::DarkGray));
    f.render_widget(swap_gauge, rows[1]);

    // Network summary
    let net_lines: Vec<Line> = app
        .nets
        .iter()
        .take(4)
        .map(|n| {
            Line::from(vec![
                Span::styled(
                    format!("{:<8}", truncate(&n.iface, 8)),
                    Style::default().fg(Color::Cyan),
                ),
                Span::raw(format!(
                    " ↓{} ↑{}",
                    human_bytes(n.rx_bytes as f64),
                    human_bytes(n.tx_bytes as f64)
                )),
            ])
        })
        .collect();
    let net_para = Paragraph::new(net_lines);
    f.render_widget(net_para, rows[2]);
}

fn draw_processes(f: &mut Frame, app: &App, area: Rect) {
    let sort_indicator = |col: SortBy| {
        if app.sort_by == col { "▼ " } else { "  " }
    };

    let header_cells = vec![
        Cell::from(format!("{}PID", sort_indicator(SortBy::Pid)))
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from(format!("{}CPU%", sort_indicator(SortBy::Cpu)))
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from(format!("{}MEM", sort_indicator(SortBy::Mem)))
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from("VIRT")
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from("STATUS")
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from("USER")
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from(format!("{}NAME", sort_indicator(SortBy::Name)))
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
        Cell::from("COMMAND")
            .style(Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
    ];

    let header = Row::new(header_cells)
        .style(Style::default().bg(Color::DarkGray))
        .height(1);

    let rows: Vec<Row> = app
        .processes
        .iter()
        .skip(app.scroll_offset)
        .map(|p| {
            let cpu_color = if p.cpu_pct > 50.0 {
                Color::Red
            } else if p.cpu_pct > 20.0 {
                Color::Yellow
            } else {
                Color::Green
            };

            Row::new(vec![
                Cell::from(p.pid.to_string()),
                Cell::from(format!("{:.1}", p.cpu_pct))
                    .style(Style::default().fg(cpu_color)),
                Cell::from(human_bytes(p.mem_bytes as f64)),
                Cell::from(human_bytes(p.virtual_mem as f64)),
                Cell::from(truncate(&p.status, 8).to_string()),
                Cell::from(truncate(&p.user, 10).to_string()),
                Cell::from(truncate(&p.name, 15).to_string()),
                Cell::from(truncate(&p.cmd, 40).to_string()),
            ])
        })
        .collect();

    let table = Table::new(
        rows,
        [
            Constraint::Length(7),  // PID
            Constraint::Length(7),  // CPU%
            Constraint::Length(8),  // MEM
            Constraint::Length(8),  // VIRT
            Constraint::Length(9),  // STATUS
            Constraint::Length(11), // USER
            Constraint::Length(16), // NAME
            Constraint::Min(10),    // COMMAND
        ],
    )
    .header(header)
    .block(
        Block::default()
            .title(format!(
                " Processes ({}) ",
                app.processes.len()
            ))
            .borders(Borders::ALL)
            .style(Style::default().fg(Color::Cyan)),
    )
    .row_highlight_style(Style::default().add_modifier(Modifier::REVERSED));

    let mut state = TableState::default();
    f.render_stateful_widget(table, area, &mut state);
}

fn draw_footer(f: &mut Frame, area: Rect) {
    let text = Line::from(vec![
        Span::styled(" q", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":quit  "),
        Span::styled("c", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":sort cpu  "),
        Span::styled("m", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":sort mem  "),
        Span::styled("p", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":sort pid  "),
        Span::styled("n", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":sort name  "),
        Span::styled("↑↓ / k j", Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
        Span::raw(":scroll"),
    ]);
    let para = Paragraph::new(text).alignment(Alignment::Left);
    f.render_widget(para, area);
}

fn truncate(s: &str, max: usize) -> &str {
    if s.len() <= max {
        s
    } else {
        &s[..max]
    }
}
