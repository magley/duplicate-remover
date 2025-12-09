module cli.exporter;

import util;
import vendor.clyd;
import exporting;

enum ExportSettings_JSON_QuickInclude_CmdString
{
    None = "none",
    LargestInEachGroup = "largest",
    SmallestInEachGroup = "smallest",
    AllButLargestInEachGroup = "except-largest",
    AllButSmallestInEachGroup = "except-smallest",
}

ExportSettings_JSON.QuickInclude to(ExportSettings_JSON_QuickInclude_CmdString e)
{
    final switch (e) with (ExportSettings_JSON_QuickInclude_CmdString)
    {
    case None:
        return ExportSettings_JSON.QuickInclude.None;
    case LargestInEachGroup:
        return ExportSettings_JSON.QuickInclude.LargestInEachGroup;
    case SmallestInEachGroup:
        return ExportSettings_JSON.QuickInclude.SmallestInEachGroup;
    case AllButLargestInEachGroup:
        return ExportSettings_JSON.QuickInclude.AllButLargestInEachGroup;
    case AllButSmallestInEachGroup:
        return ExportSettings_JSON.QuickInclude.AllButSmallestInEachGroup;
    }
}

ExportSettings get_export_settings(FileType type, Command cmd)
{
    ExportSettings s;

    final switch (type) with (FileType)
    {
    case JSON:
        s.json.quick_include = cmd.args["export-json-quick-include"]
            .enumval_or(ExportSettings_JSON_QuickInclude_CmdString.None)
            .to();
        break;
    case JSON_Simple:
        break;
    case XML:
        break;
    case CSV:
        break;
    }

    return s;
}
