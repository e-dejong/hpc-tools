# HPC Tools

A collection of handy scripts for high-performance computing (HPC) environments, focused on:

- Scratch storage management
- SLURM job utilities
- Storage health checks
- Backup and monitoring scripts

---

## 📂 Current Scripts

| Script | Purpose |
|:------|:--------|
| `purge-check.sh` | Scan scratch space for files at risk of purge (>18 days old) and summarise high-risk directories. Supports `--summary-only` mode. |

---

## 🚀 Quick Start

Clone the repo:

```bash
git clone git@github.com:yourusername/hpc-tools.git
cd hpc-tools

# run the scratch scan in summary only mode
sbatch check_dates.sh --summary-only
```
