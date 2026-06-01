# LFCS Exam Lab

Local LFCS practice lab for Windows 11 + VirtualBox + Vagrant.

## Safety Model

- Vagrant machine name: `node1`
- VirtualBox VM name: `lfcs-node1`
- Existing non-lab VMs are not managed by this repo.
- State model: restore the single `base` snapshot, then run one question inject script.
- No per-question snapshots.

## Build

```powershell
$env:VAGRANT_HOME = "$PWD\.vagrant.d"
vagrant up
vagrant snapshot save node1 base
```

## Practice

```powershell
.\lab.ps1
```

The launcher always runs:

```text
vagrant snapshot restore node1 base --no-provision
vagrant ssh node1 -c "sudo bash /vagrant/inject/<qid>.sh"
```

Validation always runs inside `node1` as root:

```text
vagrant ssh node1 -c "sudo bash /vagrant/validate/<qid>.sh"
```

Exit code `0` means pass. Any non-zero exit code means fail. The final stdout line is always `RESULT: PASS` or `RESULT: FAIL - <reason>`.
