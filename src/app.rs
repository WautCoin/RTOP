use crate::collect::{Collector, CpuStats, MemStats, NetStats, ProcessInfo};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SortBy {
    Cpu,
    Mem,
    Pid,
    Name,
}

pub struct App {
    collector: Collector,
    pub cpu: CpuStats,
    pub mem: MemStats,
    pub nets: Vec<NetStats>,
    pub processes: Vec<ProcessInfo>,
    pub sort_by: SortBy,
    pub scroll_offset: usize,
}

impl App {
    pub fn new() -> Self {
        let collector = Collector::new();
        App {
            cpu: CpuStats {
                global_usage: 0.0,
                core_usages: vec![],
            },
            mem: MemStats {
                total: 0,
                used: 0,
                swap_total: 0,
                swap_used: 0,
            },
            nets: vec![],
            processes: vec![],
            sort_by: SortBy::Cpu,
            scroll_offset: 0,
            collector,
        }
    }

    pub fn refresh(&mut self) {
        self.collector.refresh();
        self.cpu = self.collector.cpu_stats();
        self.mem = self.collector.mem_stats();
        self.nets = self.collector.net_stats();
        self.processes = self.collector.processes();
        self.sort_processes();
    }

    fn sort_processes(&mut self) {
        match self.sort_by {
            SortBy::Cpu => self
                .processes
                .sort_by(|a, b| b.cpu_pct.partial_cmp(&a.cpu_pct).unwrap()),
            SortBy::Mem => self.processes.sort_by(|a, b| b.mem_bytes.cmp(&a.mem_bytes)),
            SortBy::Pid => self.processes.sort_by(|a, b| a.pid.cmp(&b.pid)),
            SortBy::Name => self.processes.sort_by(|a, b| a.name.cmp(&b.name)),
        }
    }

    pub fn sort_by_cpu(&mut self) {
        self.sort_by = SortBy::Cpu;
        self.sort_processes();
        self.scroll_offset = 0;
    }

    pub fn sort_by_mem(&mut self) {
        self.sort_by = SortBy::Mem;
        self.sort_processes();
        self.scroll_offset = 0;
    }

    pub fn sort_by_pid(&mut self) {
        self.sort_by = SortBy::Pid;
        self.sort_processes();
        self.scroll_offset = 0;
    }

    pub fn sort_by_name(&mut self) {
        self.sort_by = SortBy::Name;
        self.sort_processes();
        self.scroll_offset = 0;
    }

    pub fn scroll_up(&mut self) {
        self.scroll_offset = self.scroll_offset.saturating_sub(1);
    }

    pub fn scroll_down(&mut self) {
        let max = self.processes.len().saturating_sub(1);
        if self.scroll_offset < max {
            self.scroll_offset += 1;
        }
    }
}
