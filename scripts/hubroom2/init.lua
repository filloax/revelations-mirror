local hub2 = require "scripts.hubroom2"

require "scripts.hubroom2.version"
require "scripts.hubroom2.data"
require "scripts.hubroom2.savedata"
require "scripts.hubroom2.utilities"
require "scripts.hubroom2.hub"
require "scripts.hubroom2.statues"

Isaac.ConsoleOutput("Hubroom 2.0." .. hub2.ReleaseVersion .. " (" .. hub2.Version .. ") loaded.\n")

return hub2