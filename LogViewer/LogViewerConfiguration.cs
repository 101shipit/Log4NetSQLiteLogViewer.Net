using System.Configuration;

namespace LogViewer
{
	public class LogViewerConfiguration : ConfigurationSection
	{
		private static readonly LogViewerConfiguration Config = ConfigurationManager.GetSection("LogViewerConfiguration") as LogViewerConfiguration;

		[ConfigurationProperty("logDbPath", IsRequired = false)]
		public string LogDbPath
		{
			get
			{
				return (string)this["logDbPath"];
			}
			set
			{
				this["logDbPath"] = value;
			}
		}

		[ConfigurationProperty("pageSize", DefaultValue = 50, IsRequired = false)]
		public int PageSize
		{
			get
			{
				return (int)this["pageSize"];
			}
			set
			{
				this["pageSize"] = value;
			}
		}

		[ConfigurationProperty("defaultDbFileName", IsRequired = false)]
		public string DefaultDbFileName
		{
			get
			{
				return (string)this["defaultDbFileName"];
			}
			set
			{
				this["defaultDbFileName"] = value;
			}
		}

		public static LogViewerConfiguration Settings
		{
			get { return Config; }
		}
	}
	
}