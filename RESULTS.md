## Summary
All results below are collected with a 100% sampling rate.

### Key Findings

- **Disk Offloading Enabled (`offload_to_disk=true`)**
  - Database disk usage increases with higher payload sizes and concurrency.
  - RSS (memory usage) is generally lower compared to runs without disk offloading, especially for large payloads and high concurrency.
  - The number of spans received by the countexporter may be less than the number of requests, especially at high concurrency and payload sizes, indicating possible dropped spans or batching effects.
  - The number of spans received by the countexporter may be less than the number of requests, especially at high concurrency and payload sizes, due to span drops from sampling decision lag (spans expiring in the database before a decision is made).

- **Disk Offloading Disabled (`offload_to_disk=false`)**
  - No database disk usage is reported.
  - RSS (memory usage) can be significantly higher, especially for large payloads and high concurrency.
  - The number of spans sent and received is generally consistent, but memory usage can become a bottleneck.
  - The number of spans sent and received is generally consistent until memory is exhausted; span drops in this case are mainly due to the num_traces memory limitation.

### Performance Comparison

|- | Disk Offloading | Payload Size | Concurrency | Max RSS (KB) | DB Size (KB) | Spans Sent | Spans Received |
|---|-----------------|-------------|-------------|--------------|--------------|------------|---------------|
| Example | true          | 100000      | 10          | 275192       | 901261       | 29952      | 29791         |
| Example | false         | 100000      | 10          | 2195184      | N/A          | 29401      | 11434         |

Disk offloading helps control memory usage at the cost of increased disk usage. For large payloads and high concurrency, enabling disk offloading can prevent excessive RSS growth, but may result in more disk I/O. Span drops can occur in both cases, but for different reasons (see below).

Span drops with disk offloading enabled (`offload_to_disk=true`) are primarily due to the sampling decision lagging behind, causing spans to expire in the database before a decision is made. This is fixable with better synchronization between sampling decision making and database entry expiry control. With disk offloading disabled (`offload_to_disk=false`), span drops are mainly caused by the `num_traces` limitation in memory.

### Raw run-all output

```
Running with offload_to_disk=true, payload_size=10000, concurrency=1
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 72049 KB
  db size 144852 KB
  db size 208285 KB
  db size 248040 KB
  db size 231184 KB
  db size 271585 KB
  db size 317339 KB
  db size 247727 KB
  db size 316327 KB
  db size 386931 KB
  Sent 56982 spans
  db size 306186 KB
  db size 301376 KB
  db size 301376 KB
  db size 117290 KB
  db size 117290 KB
  db size 117290 KB
  db size 65548 KB
  db size 65548 KB
  db size 65548 KB
  db size 65548 KB
  CountExporter: 56982 requests, 56420 spans received
  tail collector RSS high watermark: 139832 KB
Running with offload_to_disk=true, payload_size=10000, concurrency=10
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 762 KB
  db size 23465 KB
  db size 39824 KB
  db size 168686 KB
  db size 248831 KB
  db size 306248 KB
  db size 351830 KB
  db size 330471 KB
  db size 364442 KB
  db size 499460 KB
  db size 357412 KB
  Sent 10744 spans
  Sent 10859 spans
  Sent 10516 spans
  Sent 10658 spans
  Sent 10690 spans
  Sent 10305 spans
  Sent 10816 spans
  Sent 10653 spans
  Sent 10368 spans
  Sent 10725 spans
  db size 423514 KB
  db size 475057 KB
  db size 425531 KB
  db size 417747 KB
  db size 586064 KB
  db size 450837 KB
  db size 415014 KB
  db size 454962 KB
  db size 218750 KB
  db size 218750 KB
  db size 218750 KB
  db size 65606 KB
  db size 65606 KB
  db size 65606 KB
  db size 65606 KB
  db size 65606 KB
  CountExporter: 106334 requests, 50992 spans received
  tail collector RSS high watermark: 238920 KB
Running with offload_to_disk=true, payload_size=100000, concurrency=1
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 3630 KB
  db size 16773 KB
  db size 71690 KB
  db size 159653 KB
  db size 232718 KB
  db size 267239 KB
  db size 299898 KB
  db size 254116 KB
  db size 334237 KB
  db size 394072 KB
  Sent 9850 spans
  db size 400264 KB
  db size 525110 KB
  db size 620333 KB
  db size 627506 KB
  db size 579653 KB
  db size 600711 KB
  db size 276847 KB
  db size 276847 KB
  db size 276847 KB
  db size 65643 KB
  db size 65643 KB
  db size 65643 KB
  db size 65644 KB
  db size 65644 KB
  db size 65644 KB
  CountExporter: 9850 requests, 9850 spans received
  tail collector RSS high watermark: 127552 KB
Running with offload_to_disk=true, payload_size=100000, concurrency=10
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 2 KB
  db size 1670 KB
  db size 3632 KB
  db size 15790 KB
  db size 21579 KB
  db size 55116 KB
  db size 54332 KB
  db size 100522 KB
  db size 124937 KB
  db size 98953 KB
  db size 119157 KB
  Sent 3002 spans
  Sent 2668 spans
  Sent 2989 spans
  Sent 2912 spans
  Sent 2830 spans
  Sent 2757 spans
  Sent 3195 spans
  Sent 3155 spans
  db size 93071 KB
  Sent 3153 spans
  Sent 3291 spans
  db size 207320 KB
  db size 284413 KB
  db size 404750 KB
  db size 503803 KB
  db size 432227 KB
  db size 564524 KB
  db size 647104 KB
  db size 510653 KB
  db size 533769 KB
  db size 722239 KB
  db size 427404 KB
  db size 527057 KB
  db size 558739 KB
  db size 594144 KB
  db size 391462 KB
  db size 525710 KB
  db size 403323 KB
  db size 344492 KB
  db size 420213 KB
  db size 434365 KB
  db size 544306 KB
  db size 585097 KB
  db size 565131 KB
  db size 600154 KB
  db size 634301 KB
  db size 819535 KB
  db size 469758 KB
  db size 541850 KB
  db size 414481 KB
  db size 577660 KB
  db size 494117 KB
  db size 472972 KB
  db size 609290 KB
  db size 656181 KB
  db size 901261 KB
  db size 364333 KB
  db size 353933 KB
  db size 65965 KB
  db size 65965 KB
  db size 65965 KB
  db size 65965 KB
  db size 65965 KB
  db size 65965 KB
  CountExporter: 29952 requests, 29791 spans received
  tail collector RSS high watermark: 275192 KB
Running with offload_to_disk=false, payload_size=10000, concurrency=1
  Sent 93072 spans
  CountExporter: 10000 requests, 10000 spans received
  tail collector RSS high watermark: 276572 KB
Running with offload_to_disk=false, payload_size=10000, concurrency=10
  Sent 19999 spans
  Sent 20335 spans
  Sent 19660 spans
  Sent 19893 spans
  Sent 19804 spans
  Sent 20202 spans
  Sent 19217 spans
  Sent 20558 spans
  Sent 20289 spans
  Sent 20289 spans
  CountExporter: 10122 requests, 10122 spans received
  tail collector RSS high watermark: 344928 KB
Running with offload_to_disk=false, payload_size=100000, concurrency=1
  Sent 22557 spans
  CountExporter: 22557 requests, 22557 spans received
  tail collector RSS high watermark: 1334248 KB
Running with offload_to_disk=false, payload_size=100000, concurrency=10
  Sent 2403 spans
  Sent 3528 spans
  Sent 2289 spans
  Sent 2193 spans
  Sent 2712 spans
  Sent 2727 spans
  Sent 2406 spans
  Sent 2185 spans
  Sent 3379 spans
  Sent 5579 spans
  CountExporter: 11434 requests, 11434 spans received
  tail collector RSS high watermark: 2195184 KB
```

