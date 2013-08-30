<%@ Page Title="View Log" Language="C#" AutoEventWireup="True" CodeBehind="ViewLog.aspx.cs" Inherits="LogViewer.ViewLog" %>
<%@ Register Assembly="Ext.Net" Namespace="Ext.Net" TagPrefix="ext" %>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" lang="en-gb" xml:lang="en-gb" runat="server" id="html">
<head id="Head1" runat="server">
    <title>Log Viewer</title>

	<style type="text/css">
		html, body { font: 82%/170% tahoma,arial,helvetica,sans-serif; }
		table { border-collapse: collapse; }
		.x-grid3-row-selected { background-color: #eee !important; }
		.x-grid3-row .x-grid3-td-expander { vertical-align:top; }
		.x-grid3-body-cell { user-select:text!important; -moz-user-select:text!important; -khtml-user-select:text!important; -webkit-user-select:text!important; }
		.mylabel { height:20px; padding-left: 5px; }
		.sonetto-log-grid { width:40%; }
		.sonetto-log-east-details { width:60%; }
		.sonetto-log-south-details { height:60%; }
		.log-details pre { font-family: "courier new", Monospace; }
		.log-details pre.message pre.exception { white-space:pre-wrap; }
		.log-details { padding:10px; }
		.log-details > h3 { font-size:1em; margin-top:1em; }
		.log-details > h3:first-child { margin-top:0; }
		
		.level-info { color:#777; }
		.level-warn { color:#d70; }
		.level-error { color:#b00; }
		.level-fatal { color:#f00; font-weight:bold; }
		
		.template-level-data { vertical-align:middle; }
		
		.log-summary { width:100%; }
		.log-summary th { background:#eee; font-weight:bold; }
		.log-summary th, .log-summary td { border:1px solid #ccc; padding:0.25em; vertical-align:top; }
		
	</style>
	<script type="text/javascript">
		var LogViewer = {
			views: {
				allWarningsAndMore: function () {
					LogViewer.views.applyFilters.call(this, function () {
						var filters = GridPanel1.filters.filters.items;

						filters[2].setValue(['WARN', 'ERROR', 'FATAL']);
						filters[2].setActive(true);
					});
				},

				warningsAndMoreToday: function () {
					LogViewer.views.applyFilters.call(this, function () {
						var filters = GridPanel1.filters.filters.items;

						filters[1].setValue({ 'on': new Date() });
						filters[1].setActive(true);

						filters[2].setValue(['WARN', 'ERROR', 'FATAL']);
						filters[2].setActive(true);
					});
				},

				warningsAndMoreYesterday: function () {
					LogViewer.views.applyFilters.call(this, function () {
						var today = new Date(),
							yesterday = new Date(),
							filters = GridPanel1.filters.filters.items;

						yesterday = new Date(yesterday.setDate(today.getDate() - 1));

						filters[1].setValue({ 'on': yesterday });
						filters[1].setActive(true);

						filters[2].setValue(['WARN', 'ERROR', 'FATAL']);
						filters[2].setActive(true);
					});
				},

				warningsAndMorePastWeek: function () {
					LogViewer.views.applyFilters.call(this, function () {
						var today = new Date(),
							pastWeek = new Date(new Date().setDate(today.getDate() - 7)),
							tomorrow = new Date(new Date().setDate(today.getDate() + 1))
						filters = GridPanel1.filters.filters.items;

						filters[1].setValue({ 'after': pastWeek }); // not passing true here unsets any filters from previous queries e.g. 'on's
						filters[1].setValue({ 'before': tomorrow }, true); // preserve after, as setting after unchecked everything else
						filters[1].setActive(true);

						filters[2].setValue(['WARN', 'ERROR', 'FATAL']);
						filters[2].setActive(true);
					});
				},

				goTo: function () {
					var value = this.getValue();

					if (value.trim().length == 0)
						return;

					LogViewer.views.applyFilters.call(this, function () {
						GridPanel1.filters.filters.items[0].setValue({ 'eq': parseInt(value, 10) });
					});
				},

				clear: function () {
					LogViewer.views.applyFilters.call(this);
				},

				applyFilters: function (action) {
					var i, numFilters, parentMenu = this.parentMenu ? this.parentMenu.ownerCt : null;

					if (parentMenu != null) {
						parentMenu.setText(this.text);
						parentMenu.setIconClass(this.iconCls);
					}

					GridPanel1.filters.clearFilters();

					GridPanel1.suspendEvents();

					if (action) {
						action();
					}

					GridPanel1.resumeEvents();

					GridPanel1.filters.reload();
				},

				initFilters: function () {
					var filters = this.filters.filters,
						dateFilter = filters.get('Date'),
						today = new Date(),
						i, len, pickerMenu;

					for (i = 0, len = dateFilter.menuItems.length; i < len; i++) {
						if (dateFilter.menuItems) // IE8 and below
							continue;

						item = dateFilter.menuItems[i];
						if (item !== '-') {
							pickerMenu = dateFilter.menu.get(i).menu;
							if (pickerMenu && pickerMenu.picker) {
								// IE sometimes seems not to have it...
								pickerMenu.picker.setMaxDate(today);
							}
						}
					}

					/* need to handle case where page is open for more than a day and update. avoid setTimeout if possible */
				}
			},

			afterRender: function () {
				LogViewer.detailsPane.setContainingPanel.call(this);
				LogViewer.views.initFilters.call(this);
				LogViewer.views.allWarningsAndMore.call(this);
				

			},



			getRowClass: function (record, rowIndex, p, ds) {
				return 'level-' + record.data.Level.toLowerCase();
			},



			rowSelected: function (selectionModel, rowIndex, record) {
				Store2.removeAll();
				Store2.add(record);
			},

			detailsPane: {
				containingPanel: null,

				setContainingPanel: function () {
					LogViewer.detailsPane.containingPanel = this.ownerCt;
				},

				doMove: function (panelToHide, panelToShow) {
					panelToHide.hide();
					panelToShow.add(DataView1);
					panelToShow.show();
					LogViewer.detailsPane.containingPanel.doLayout();
					this.parentMenu.ownerCt.setIconClass(this.iconCls);
					this.parentMenu.ownerCt.setText('Details: ' + this.text);
				},

				move: function (menuItem, pressed) {
					var containingPanel = LogViewer.detailsPane.containingPanel;

					if (pressed) {
						switch (menuItem.text) {
							case "Bottom":
								LogViewer.detailsPane.doMove.call(this, RightDetails, BottomDetails);
								break;

							case "Right":
								LogViewer.detailsPane.doMove.call(this, BottomDetails, RightDetails);
								break;

							default:
								throw "Unknown location: " + menuItem.text;
								break;
						}
					}
				}
			}
		};

	</script>
</head>
<body id="Body1" runat="server">
	<form id="form1" runat="server">
	<ext:ResourceManager ID="ResourceManager1" runat="server" IDMode="Explicit" />
	<ext:Hidden id="LogGridData" runat="server" />
	<ext:Viewport ID="Viewport1" runat="server" Layout="border">
	<Items>
	
	<ext:BorderLayout ID="BorderLayout1" runat="server" IDMode="Explicit">
		<North>
			<ext:Label ID="mylabel" IDMode="Explicit" runat="server" Cls="mylabel" />
		</North>
		<Center>
			<ext:GridPanel id="GridPanel1" IDMode="Explicit" Cls="sonetto-log-grid" runat="server" AutoExpandColumn="Message">
				<Store>
					<ext:Store ID="Store1" IDMode="Explicit" runat="server" RemoteSort="true" OnRefreshData="Store1_RefreshData">
						<Proxy>
							<ext:PageProxy />
						</Proxy>
						<Reader>
							<ext:JsonReader IDProperty="LogId">
								<Fields>
									<ext:RecordField Name="LogId" Type="Int" />
									<ext:RecordField Name="Date" Type="Date" />
									<ext:RecordField Name="Thread" Type="Int" />
									<ext:RecordField Name="Level" Type="String"/>
									<ext:RecordField Name="Logger" Type="String"/>
									<ext:RecordField Name="Message" Type="String"/>
									<ext:RecordField Name="Exception" Type="String"/>
								</Fields>
							</ext:JsonReader>
						</Reader>
						<DirectEventConfig IsUpload="true" />
						<BaseParams>
							<ext:Parameter Name="start" Value="0" Mode="Raw" />
							<ext:Parameter Name="limit" Value="50" Mode="Raw" />
							<ext:Parameter Name="sort" Value="" />
							<ext:Parameter Name="dir" Value="DESC" />
						</BaseParams>
						<SortInfo Field="LogId" Direction="DESC" />
					</ext:Store>
				</Store>
				<ColumnModel runat="server">
					<Columns>
						<ext:Column Header="Log Id" DataIndex="LogId" width="50" />
						<ext:Column Header="Date" DataIndex="Date" width="155">
							<Renderer Format="Date" FormatArgs="'D Y-m-d H:i:s.u'" />
						</ext:Column>
						<ext:Column Header="Level" DataIndex="Level" width="60" Align="Center">
							
						</ext:Column>
						<ext:Column Header="Logger" DataIndex="Logger" width="220" />
						<ext:Column Header="Message" DataIndex="Message" hidden="true">
							<Renderer Fn="Ext.util.Format.htmlEncode" />
						</ext:Column>
					</Columns>
				</ColumnModel>
				<SelectionModel>
					<ext:RowSelectionModel ID="RowSelectionModel1" runat="server" SingleSelect="true">
						<Listeners>
							<RowSelect Fn="LogViewer.rowSelected" />
						</Listeners>
					</ext:RowSelectionModel>
				</SelectionModel>
				<View>
					<ext:GridView runat="server">
						<GetRowClass Fn="LogViewer.getRowClass" />						
					</ext:GridView>
				</View>
				<LoadMask ShowMask="true" Msg="Getting data..." />
				<TopBar>
					<ext:Toolbar ID="Toolbar1" runat="server">
						<Items>
							<ext:Button ID="ViewButton" runat="server" ShowText="true" PrependText="View " Text="Common views" IDMode="Explicit">
								<Menu>
									<ext:Menu runat="server">
										<Items>
											<ext:CheckMenuItem ID="CheckMenuItem2" runat="server" Text="All warnings, errors and fatals" Icon="Date" IDMode="Explicit" Checked="true" > 
												<Listeners>
													<Click Fn="LogViewer.views.allWarningsAndMore" />
												</Listeners>
											</ext:CheckMenuItem>
											<ext:CheckMenuItem runat="server" Text="Warnings, errors and fatals today" Icon="Date">
												<Listeners>
													<Click Fn="LogViewer.views.warningsAndMoreToday" />
												</Listeners>
											</ext:CheckMenuItem>
											<ext:CheckMenuItem runat="server" Text="Warnings, errors and fatals yesterday" Icon="DatePrevious">
												<Listeners>
													<Click Fn="LogViewer.views.warningsAndMoreYesterday" />
												</Listeners>
											</ext:CheckMenuItem>
											<ext:CheckMenuItem ID="CheckMenuItem1" runat="server" Text="Warnings, errors and fatals in the past week" Icon="DateMagnify">
												<Listeners>
													<Click Fn="LogViewer.views.warningsAndMorePastWeek" />
												</Listeners>
											</ext:CheckMenuItem>
											<ext:MenuSeparator />
											<ext:MenuItem runat="server" Text="All items (no filters)">
												<Listeners>
													<Click Fn="LogViewer.views.clear" />
												</Listeners>
											</ext:MenuItem>
										</Items>
									</ext:Menu>
								</Menu>
							</ext:Button>
							<ext:ToolbarFill ID="ToolbarFill1" runat="server" />
							<ext:Button ID="PreviewPlace" runat="server" Text="Details Pane">
								<QTipCfg Title="Details pane location" Text="Show page on bottom or right" Cls="tooltip-heading-and-body" />
								<Menu>
									<ext:Menu runat="server">
										<Items>
											<ext:CheckMenuItem Text="Bottom" Icon="ApplicationTileVertical"  Checked="true" Group="pane-group" CheckHandler="LogViewer.detailsPane.move" />
											<ext:CheckMenuItem Text="Right" Icon="ApplicationTileHorizontal" Group="pane-group" CheckHandler="LogViewer.detailsPane.move" />
										</Items>
									</ext:Menu>
								</Menu>
							</ext:Button>
						</Items>
					</ext:Toolbar>
				</TopBar>
				<BottomBar>
					<ext:PagingToolbar ID="PagingToolbar1" runat="server" PageSize="50">
						<Items>
							<ext:ToolbarSpacer runat="server" Width="10" />
							<ext:SelectBox runat="server" Width="100" Cls="no-right-border-radius" FieldLabel="Page size" LabelWidth="45">
								<Items>
									<ext:ListItem Text="20" />
									<ext:ListItem Text="50" />
									<ext:ListItem Text="100" />
									<ext:ListItem Text="500" />
								</Items>
								<SelectedItem Value="50" />
								<Listeners>
									<Select Handler="#{PagingToolbar1}.pageSize = parseInt(this.getValue()); #{PagingToolbar1}.doLoad();" />
								</Listeners>
							</ext:SelectBox>
							<ext:ToolbarSpacer ID="ToolbarSpacer1" runat="server" Width="10" />
							<ext:TriggerField ID="GoToTriggerField" runat="server" EmptyText="Log id" FieldLabel="Jump to" Cls="no-right-border-radius" Width="120" LabelWidth="40">
								<Triggers>
									<ext:FieldTrigger Icon="Search" Tag="search" />
								</Triggers>
								<Listeners>
									<TriggerClick Fn="LogViewer.views.goTo" />
								</Listeners>
							</ext:TriggerField>
						</Items>
					</ext:PagingToolbar>
				</BottomBar>
				<Plugins>
					<ext:GridFilters runat="server" ID="GridFilters1">
						<Filters>
							<ext:NumericFilter DataIndex="LogId" />
							<ext:DateFilter DataIndex="Date">
								<DatePickerOptions runat="server" TodayText="Now" />
							</ext:DateFilter>
							<ext:ListFilter DataIndex="Level" Options="DEBUG, INFO, WARN, ERROR, FATAL" />
							<ext:StringFilter DataIndex="Logger" />
							<ext:StringFilter DataIndex="Message" />
						</Filters>
					</ext:GridFilters>
				</Plugins>
				<Listeners>
					<AfterRender Fn="LogViewer.afterRender" />
				</Listeners>
			</ext:GridPanel>
		</Center>
		<South Floatable="false">
			<ext:Panel ID="BottomDetails" Title="Details" Cls="sonetto-log-south-details"  Height="300" runat="server" Split="true" Collapsible="true" AutoScroll="true">
				<Items>
						<ext:DataView ID="DataView1" IDMode="Explicit" runat="server" EmptyText="No details to display" ItemSelector=".log-details">
							<Store>
								<ext:Store ID="Store2" IDMode="Explicit" runat="server">
									<Reader>
										<ext:JsonReader IDProperty="LogId" >
											<Fields>
												<ext:RecordField Name="LogId" Type="Int" />
												<ext:RecordField Name="Date" Type="Date" />
												<ext:RecordField Name="Thread" Type="Int" />
												<ext:RecordField Name="Level" Type="String"/>
												<ext:RecordField Name="Logger" Type="String"/>
												<ext:RecordField Name="Message" Type="String"/>
												<ext:RecordField Name="Exception" Type="String"/>
											</Fields>
										</ext:JsonReader>
									</Reader>
								</ext:Store>
							</Store>
							<Template ID="Template1" IDMode="Explicit" runat="server">
								<Html>
									<tpl for=".">
										<div class="log-details">
											<table class="log-summary">
												<thead>
													<th class="logId">Log Id</th>
													<th class="date">Date</th>
													<th class="level">Level</th>
													<th class="thread">Thread</th>
													<th class="logger">Logger</th>
												</thead>
												<tbody>
													<tr>
														<td>{LogId}</td>
														<td>{Date:date("D Y-m-d H:i:s.u")}</td>
														<td>{Level}</td>
														<td>{Thread}</td>
														<td>{Logger}</td>
													</tr>											
												</tbody>
											</table>

											<h3>Message:</h3>
											<pre class="message">{Message:htmlEncode}</pre>

											<h3>Exception:</h3>
											<pre class="exception">{Exception:htmlEncode}</pre>
										</div>
									</tpl>
								</Html>
								<Functions>
									<ext:JFunction Name="levelRenderer" Fn="LogViewer.levelRenderer" />
								</Functions>
							</Template>
						</ext:DataView>
					</Items>
			</ext:Panel>
		</South>
		<East Floatable="false">
			<ext:Panel ID="RightDetails" Title="Details" Hidden="true" Cls="sonetto-log-east-details"  Split="true" runat="server" Collapsible="true" AutoScroll="true">
				
			</ext:Panel>
		</East>
	</ext:BorderLayout>
	</Items>
	</ext:Viewport>
    </form>
</body>
</html>