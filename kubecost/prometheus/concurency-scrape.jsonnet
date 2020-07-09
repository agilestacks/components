local secretKey = std.extVar("SECRET_KEY");
local currentScrapes = std.extVar("CURRENT_SCRAPES");
local kubecostScrape = std.extVar("KUBECOST_SCRAPE");

local updatedConfigs = std.uniq(
    [kubecostScrape]
    +
    currentScrapes
);

{
    stringData: {
        [secretKey]: std.manifestYamlDoc(updatedConfigs)
    }
}
