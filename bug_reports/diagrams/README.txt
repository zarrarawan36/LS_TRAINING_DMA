bug_reports/diagrams/  -  waveform screenshots for the reports
=====================================================================

Record the waves of the failing run:
  cd ../../sim
  make run TEST=<test> SEED=<n> WAVES=1      -> sim/waves.vcd (open with GTKWave)

Save a screenshot per report, named after the report number, e.g.
  report_01_wave.png
with the signal names, the time cursor on the first wrong value and the
relevant handshake signals visible. Keep .vcd files out of this folder
unless they are small; the test name and seed are enough to re-create them.
