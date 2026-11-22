testplan/diagrams/  -  diagrams of your verification environment
=====================================================================

Keep the draw.io source AND an exported image of every diagram:

  uvm_env.drawio         + uvm_env.png        (or .svg)
      UVM environment: provided agents, your agents, env, scoreboard,
      reference model, coverage collector, and how they connect to the DUT
  scoreboard.drawio      + scoreboard.png     (or .svg)
      scoreboard / checker: what goes in, what the reference model
      predicts, what is compared and when
  test_hierarchy.drawio  + test_hierarchy.png (or .svg)
      base test -> derived tests, and the sequences each test starts

The names match the diagram slots of docs/j3_mm_rd/testplan.html: when a
page stores a link instead of an embedded image, it looks for the file here.

draw.io: File > Export as > PNG (or SVG), tick "Include a copy of my
diagram" so the exported image can be opened and edited again.
Use the colour legend of the documents (docs/specs/).
