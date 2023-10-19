# GatherTown SFU server notes

For SFUs we use the node type c5a. This node type uses the CPU *3.3GHz AMD EPYC 7002*.

> NOTE: Amazon advises [c5n instance types](https://aws.amazon.com/ec2/instance-types/) for high network performance applications.

## Part1: boot variables

Adding `nosmt mitigations=off`
[kernel
options](https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html?highlight=kernel%20parameters):


```
 nosmt           [KNL,MIPS,PPC,S390] Disable symmetric multithreading (SMT).
                        Equivalent to smt=1.

                        [KNL,X86,PPC] Disable symmetric multithreading (SMT).
                        nosmt=force: Force disable SMT, cannot be undone
                                     via the sysfs control file.
[...]
mitigations=
                        [X86,PPC,S390,ARM64] Control optional mitigations for
                        CPU vulnerabilities.  This is a set of curated,
                        arch-independent options, each of which is an
                        aggregation of existing arch-specific options.

                        off
                                Disable all optional CPU mitigations.  This
                                improves system performance, but it may also
                                expose users to several CPU vulnerabilities.
                                Equivalent to: if nokaslr then kpti=0 [ARM64]
                                               gather_data_sampling=off [X86]
                                               kvm.nx_huge_pages=off [X86]
                                               l1tf=off [X86]
                                               mds=off [X86]
                                               mmio_stale_data=off [X86]
                                               no_entry_flush [PPC]
                                               no_uaccess_flush [PPC]
                                               nobp=0 [S390]
                                               nopti [X86,PPC]
                                               nospectre_bhb [ARM64]
                                               nospectre_v1 [X86,PPC]
                                               nospectre_v2 [X86,PPC,S390,ARM64]
                                               retbleed=off [X86]
                                               spec_store_bypass_disable=off [X86,PPC]
                                               spectre_v2_user=off [X86]
                                               srbds=off [X86,INTEL]
                                               ssbd=force-off [ARM64]
                                               tsx_async_abort=off [X86]

                                Exceptions:
                                               This does not have any effect on
                                               kvm.nx_huge_pages when
                                               kvm.nx_huge_pages=force.

                        auto (default)
                                Mitigate all CPU vulnerabilities, but leave SMT
                                enabled, even if it's vulnerable.  This is for
                                users who don't want to be surprised by SMT
                                getting disabled across kernel upgrades, or who
                                have other ways of avoiding SMT-based attacks.
                                Equivalent to: (default behavior)

                        auto,nosmt
                                Mitigate all CPU vulnerabilities, disabling SMT
                                if needed.  This is for users who always want to
                                be fully mitigated, even if it means losing SMT.
                                Equivalent to: l1tf=flush,nosmt [X86]
                                               mds=full,nosmt [X86]
                                               tsx_async_abort=full,nosmt [X86]
                                               mmio_stale_data=full,nosmt [X86]
                                               retbleed=auto,nosmt [X86]
```

## Part2: remove `powerclamp`

We blacklist `intel_powerclamp` which is not present on an AMD CPU, but will
make the configure future-proof in case we switch to Intel x86 CPUs in the
future.

## Part3: disable adaptive-rx

The feature `adaptive-rx` is not supported:

```bash
[root@ip-10-200-4-168 /]# ethtool -k eth0 | grep adaptive
[root@ip-10-200-4-168 /]#
```

Supported ethernet features for this instance type are:

```bash
$ ethtool -k eth0

Features for eth0:
rx-checksumming: on
tx-checksumming: on
	tx-checksum-ipv4: on
	tx-checksum-ip-generic: off [fixed]
	tx-checksum-ipv6: off [fixed]
	tx-checksum-fcoe-crc: off [fixed]
	tx-checksum-sctp: off [fixed]
scatter-gather: on
	tx-scatter-gather: on
	tx-scatter-gather-fraglist: off [fixed]
tcp-segmentation-offload: off
	tx-tcp-segmentation: off [fixed]
	tx-tcp-ecn-segmentation: off [fixed]
	tx-tcp-mangleid-segmentation: off [fixed]
	tx-tcp6-segmentation: off [fixed]
udp-fragmentation-offload: off
generic-segmentation-offload: on
generic-receive-offload: on
large-receive-offload: off [fixed]
rx-vlan-offload: off [fixed]
tx-vlan-offload: off [fixed]
ntuple-filters: off [fixed]
receive-hashing: on
highdma: on
rx-vlan-filter: off [fixed]
vlan-challenged: off [fixed]
tx-lockless: off [fixed]
netns-local: off [fixed]
tx-gso-robust: off [fixed]
tx-fcoe-segmentation: off [fixed]
tx-gre-segmentation: off [fixed]
tx-gre-csum-segmentation: off [fixed]
tx-ipxip4-segmentation: off [fixed]
tx-ipxip6-segmentation: off [fixed]
tx-udp_tnl-segmentation: off [fixed]
tx-udp_tnl-csum-segmentation: off [fixed]
tx-gso-partial: off [fixed]
tx-tunnel-remcsum-segmentation: off [fixed]
tx-sctp-segmentation: off [fixed]
tx-esp-segmentation: off [fixed]
tx-udp-segmentation: off [fixed]
tx-gso-list: off [fixed]
fcoe-mtu: off [fixed]
tx-nocache-copy: off
loopback: off [fixed]
rx-fcs: off [fixed]
rx-all: off [fixed]
tx-vlan-stag-hw-insert: off [fixed]
rx-vlan-stag-hw-parse: off [fixed]
rx-vlan-stag-filter: off [fixed]
l2-fwd-offload: off [fixed]
hw-tc-offload: off [fixed]
esp-hw-offload: off [fixed]
esp-tx-csum-hw-offload: off [fixed]
rx-udp_tunnel-port-offload: off [fixed]
tls-hw-tx-offload: off [fixed]
tls-hw-rx-offload: off [fixed]
rx-gro-hw: off [fixed]
tls-hw-record: off [fixed]
rx-gro-list: off
macsec-hw-offload: off [fixed]
```

## Optimise RSS for increased network performance

Receive-Side Scaling (RSS), also known as multi-queue receive, distributes network receive processing across several hardware-based receive queues,
allowing inbound network traffic to be processed by multiple CPUs.
RSS can be used to relieve bottlenecks in receive interrupt processing caused by overloading a single CPU,and to reduce network latency.

The maximum number of channels has been already set by default:

```bash
ethtool -l eth0
Channel parameters for eth0:
Pre-set maximums:
RX:             0
TX:             0
Other:          0
Combined:       8
Current hardware settings:
RX:             0
TX:             0
Other:          0
Combined:       8
```

Trying to set a number bigger than 8, which is the number of available vCPUs, is
not possible:

```bash
[root@ip-10-200-4-168 /]# ethtool -L eth0 combined 16
Cannot set device channel parameters: Invalid argument
```

We can set a smaller number but not bigger than 8.
