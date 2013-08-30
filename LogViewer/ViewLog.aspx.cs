using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Web;
using System.Xml;
using Ext.Net;

namespace LogViewer
{
	public partial class ViewLog : System.Web.UI.Page
	{
		private static readonly log4net.ILog Log = log4net.LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);
		private const string SelectClause = "Select LogId, Date, Thread, Level, Logger, Message, Exception";
		private const string SelectCountClause = "Select count(LogId)";
		private const string FromClause = "from Log";

		private SQLiteCommand _sqlcmd;
		private StringBuilder _query;

		protected void Store1_RefreshData(object sender, StoreRefreshDataEventArgs e)
		{
			//or with hardcoding - string filters = e.Parameters["gridfilters"];;
			_sqlcmd = new SQLiteCommand();
			_query = new StringBuilder();
			_query.AppendFormat("{0} {1}", SelectClause, FromClause);

			ApplyFilters(e.Parameters[GridFilters1.ParamPrefix]);

			//The Total can be set in RefreshData event as below
			//or (Store1.Proxy.Proxy as PageProxy).Total in anywhere
			//Please pay attention that the Total make a sence only during DirectEvent because
			//the Store with PageProxy get/refresh data using ajax request
			e.Total = GetTotal();

			ApplySortOrder(e);

			ApplyPaging(e);

			//-- get dataReader and bind it to Ext.net Store
			_sqlcmd.CommandText = _query.ToString();
			Store1.DataSource = GetDataReader(_sqlcmd);
			Store1.DataBind();
		}

		private void ApplyFilters(string filters)
		{
			if (string.IsNullOrEmpty(filters))
			{
				return;
			}

			_query.Append(" Where ");
			var fc = new FilterConditions(filters);
			bool firstCondition = true;
			foreach (FilterCondition condition in fc.Conditions)
			{
				Comparison comparison = condition.Comparison;
				string field = condition.Name;
				FilterType type = condition.FilterType;

				object value;
				switch (condition.FilterType)
				{
					case FilterType.Boolean:
						value = condition.ValueAsBoolean;
						break;
					case FilterType.Date:
						value = condition.ValueAsDate;
						break;
					case FilterType.List:
						value = condition.ValuesList;
						break;
					case FilterType.Numeric:
						value = condition.ValueAsInt;
						//value = condition.ValueAsDouble;
						break;
					case FilterType.String:
						value = condition.Value;
						break;
					default:
						throw new ArgumentOutOfRangeException();
				}

				if (value == null)
					continue;

				if (!firstCondition)
					_query.Append(" AND");

				_query.Append(" (");

				switch (comparison)
				{
					case Comparison.Eq:
						switch (type)
						{
							case FilterType.List:
								int valcount = 0;
								foreach (var val in (IEnumerable<String>)value)
								{
									if (valcount != 0)
										_query.Append(" OR");
									_query.Append(" " + field + " = @" + field + valcount);
									_sqlcmd.Parameters.AddWithValue("@" + field + valcount, val);
									valcount++;
								}
								break;
							case FilterType.String:
								_query.Append(" " + field + " LIKE @" + field);
								_sqlcmd.Parameters.AddWithValue("@" + field, "%" + value + "%");
								break;
							case FilterType.Date:
								var myval = (DateTime)value;
								_query.Append(" " + field + " >= @" + field + "gt" + " AND " + field + " < @" + field + "lt");
								_sqlcmd.Parameters.AddWithValue("@" + field + "gt", value);
								_sqlcmd.Parameters.AddWithValue("@" + field + "lt", myval.AddDays(1));
								break;
							default:
								_query.Append(" " + field + " = @" + field);
								_sqlcmd.Parameters.AddWithValue("@" + field, value);
								break;
						}
						break;
					case Comparison.Gt:
						_query.Append(" " + field + " > @" + field + "gt");
						_sqlcmd.Parameters.AddWithValue("@" + field + "gt", value);
						break;
					case Comparison.Lt:
						_query.Append(" " + field + " < @" + field + "lt");
						_sqlcmd.Parameters.AddWithValue("@" + field + "lt", value);
						break;
					default:
						throw new ArgumentOutOfRangeException();
				}

				firstCondition = false;
				_query.Append(" )");
			}
		}

		private void ApplySortOrder(StoreRefreshDataEventArgs e)
		{
			if (string.IsNullOrEmpty(e.Sort))
				return;

			if (e.Sort == "LogId" || e.Sort == "Date" || e.Sort == "Thread" || e.Sort == "Level" || e.Sort == "Logger" || e.Sort == "Message" || e.Sort == "Exception")
			{
				_query.Append(" ORDER BY " + e.Sort);
			}
			else
			{
				_query.Append(" ORDER BY LogId");
			}

			if (e.Dir == SortDirection.DESC)
			{
				_query.Append(" DESC");
			}
		}

		private void ApplyPaging(StoreRefreshDataEventArgs e)
		{
			_sqlcmd.Parameters.AddWithValue("@limit", e.Limit);
			_sqlcmd.Parameters.AddWithValue("@start", e.Start);
			_query.Append(" LIMIT @limit OFFSET @start");
		}

		private int GetTotal()
		{
			_sqlcmd.CommandText = _query.ToString().Replace(SelectClause, SelectCountClause);

			return GetRowCount(_sqlcmd);
		}

		private SQLiteDataReader GetDataReader(SQLiteCommand command)
		{
			var myConnection = new SQLiteConnection(GetLogDbConnectionString());
			myConnection.Open();
			command.Connection = myConnection;
			SQLiteDataReader mydatareader = command.ExecuteReader();
			return mydatareader;
		}

		private int GetRowCount(SQLiteCommand countData)
		{
			try
			{
				using (var myConnection = new SQLiteConnection(GetLogDbConnectionString()))
				{
					myConnection.Open();
					countData.Connection = myConnection;
					Log.Debug("Getting SQLite Data Row Count");
					//countData.CommandType = CommandType.Text;
					return Convert.ToInt32(countData.ExecuteScalar());
				}
			}
			catch (Exception e)
			{
				Log.Error(e);
				throw;
			}

		}

		private string GetLogDbConnectionString()
		{
			string logDBpath = null;
			if (!string.IsNullOrWhiteSpace(LogViewerConfiguration.Settings.LogDbPath) && File.Exists(LogViewerConfiguration.Settings.LogDbPath))
			{
				logDBpath = LogViewerConfiguration.Settings.LogDbPath;
			}
			else
			{
				var logFileNames = new List<string> {"SonettoLog.db","log4Net.db","SonettoLog.sqlite","Log4Net.sqlite"};
				if (!string.IsNullOrWhiteSpace(LogViewerConfiguration.Settings.DefaultDbFileName))
					logFileNames.Add(LogViewerConfiguration.Settings.DefaultDbFileName);

				string dbName = logFileNames.FirstOrDefault(dbFile => File.Exists(Request.PhysicalPath.Substring(0, Request.PhysicalPath.Length - 12) + dbFile));
				if(!string.IsNullOrWhiteSpace(dbName))
				{
					logDBpath = Request.PhysicalPath.Substring(0, Request.PhysicalPath.Length - 12) + dbName;
				}
			}
			//if (string.IsNullOrWhiteSpace(logDBpath))
			//{
			//	throw some error;
			//}
			var dbpath = new StringBuilder();
			dbpath.Append("Data Source=");
			dbpath.Append(logDBpath);
			dbpath.Append(";Version=3;");
			mylabel.Text = dbpath.ToString();
			return dbpath.ToString();
		}

		private XmlNode GetXml()
		{
			var json = LogGridData.Value.ToString();
			var eSubmit = new StoreSubmitDataEventArgs(HttpUtility.HtmlDecode(json), null);
			return eSubmit.Xml;
		}

		protected void ToXml(object sender, EventArgs e)
		{
			string strXml = GetXml().OuterXml;

			Response.Clear();
			Response.AddHeader("Content-Disposition", "attachment; filename=SonettoLog.xml");
			//Response.AddHeader("Content-Length", strXml.Length.ToString());
			Response.ContentType = "application/xml";
			Response.Write(strXml);
			Response.End();
		}

	}
}