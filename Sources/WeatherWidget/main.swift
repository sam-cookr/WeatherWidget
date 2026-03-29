import AppKit

let app = NSApplication.shared
let args = CommandLine.arguments
let delegate = AppDelegate(
    glassProbeOnly: args.contains("--glass-probe"),
    glassExperimental: args.contains("--glass-experimental")
)
app.delegate = delegate
app.run()
