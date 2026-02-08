const fs = require('fs');
const path = require('path');

// Ensures the compiled CLI entry is executable on POSIX.
// On Windows, this is unnecessary (npm creates .cmd/.ps1 shims).

const cliPath = path.resolve(__dirname, '..', '..', 'dist', 'cli.js');

if (process.platform === 'win32') {
  process.exit(0);
}

try {
  if (fs.existsSync(cliPath)) {
    fs.chmodSync(cliPath, 0o755);
  }
} catch (error) {
  // Non-fatal: publish/install usually sets correct mode.
  // This step is mainly to make local dev builds runnable.
  process.exit(0);
}
