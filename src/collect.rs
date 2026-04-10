use sysinfo::{Cpu, Networks, Pid, Process, System};

#[derive(Debug, Clone)]
pub struct CpuStats {
    pub global_usage: f32,
    pub core_usages: Vec<f32>,
}

#[derive(Debug, Clone)]
pub struct MemStats {
    pub total: u64,
    pub used: u64,
    pub swap_total: u64,
    pub swap_used: u64,
}

#[derive(Debug, Clone)]
pub struct NetStats {
    pub iface: String,
    pub rx_bytes: u64,
    pub tx_bytes: u64,
}

#[derive(Debug, Clone)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    pub cpu_pct: f32,
    pub mem_bytes: u64,
    pub virtual_mem: u64,
    pub status: String,
    pub user: String,
    pub cmd: String,
}

pub struct Collector {
    sys: System,
    networks: Networks,
}

impl Collector {
    pub fn new() -> Self {
        let mut sys = System::new_all();
        sys.refresh_all();
        let networks = Networks::new_with_refreshed_list();
        Self { sys, networks }
    }

    pub fn refresh(&mut self) {
        self.sys.refresh_all();
        self.networks.refresh(true);
    }

    pub fn cpu_stats(&self) -> CpuStats {
        let cpus = self.sys.cpus();
        CpuStats {
            global_usage: self.sys.global_cpu_usage(),
            core_usages: cpus.iter().map(|c: &Cpu| c.cpu_usage()).collect(),
        }
    }

    pub fn mem_stats(&self) -> MemStats {
        MemStats {
            total: self.sys.total_memory(),
            used: self.sys.used_memory(),
            swap_total: self.sys.total_swap(),
            swap_used: self.sys.used_swap(),
        }
    }

    pub fn net_stats(&self) -> Vec<NetStats> {
        self.networks
            .iter()
            .map(|(iface, data)| NetStats {
                iface: iface.clone(),
                rx_bytes: data.received(),
                tx_bytes: data.transmitted(),
            })
            .collect()
    }

    pub fn processes(&self) -> Vec<ProcessInfo> {
        self.sys
            .processes()
            .iter()
            .map(|(pid, proc): (&Pid, &Process)| {
                let cmd_args = proc.cmd();
                let cmd = if cmd_args.is_empty() {
                    proc.name().to_string_lossy().into_owned()
                } else {
                    cmd_args
                        .iter()
                        .map(|s| s.to_string_lossy().into_owned())
                        .collect::<Vec<_>>()
                        .join(" ")
                };

                let user = proc
                    .user_id()
                    .map(|u| u.to_string())
                    .unwrap_or_else(|| "-".to_string());

                let status = format!("{:?}", proc.status());

                ProcessInfo {
                    pid: pid.as_u32(),
                    name: proc.name().to_string_lossy().into_owned(),
                    cpu_pct: proc.cpu_usage(),
                    mem_bytes: proc.memory(),
                    virtual_mem: proc.virtual_memory(),
                    status,
                    user,
                    cmd,
                }
            })
            .collect()
    }
}
