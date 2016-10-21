
/*
 * This file is part of Jkop
 * Copyright (c) 2016 Job and Esther Technologies, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

func getTableInfo(tableName as string) static as SQLTableInfo
{
	var v = SQLTableInfo.forName(tableName)
	{%
		foreach(dataField in dataFields) {
			var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
			var dataType = dataField.getType(ctx)
			if(dataType == null) {
				ctx.error("Node has no data type", dataField)
				return(fail)
			}
			if(CustomModifierNode.exists_in(ctx, dataField, "primary")) {
				if(dataType is IntegerDataTypeNode) {
					%}
					v.addIntegerKeyColumn("{%= fieldName %}")
					{%
				}
				else if(dataType is StringDataTypeNode) {
					%}
					v.addStringKeyColumn("{%= fieldName %}")
					{%
				}
				else {
					ctx.error("Unsupported data type for primary key", dataType)
					return(fail)
				}
			}
			else {
				if(dataType is IntegerDataTypeNode) {
					%}
					v.addIntegerColumn("{%= fieldName %}")
					{%
				}
				else if(dataType is StringDataTypeNode) {
					%}
					v.addStringColumn("{%= fieldName %}")
					{%
				}
				else {
					ctx.error("Unsupported data type for data field", dataType)
					return(fail)
				}
				var isUnique = CustomModifierNode.exists_in(ctx, dataField, "unique")
				var isIndex = CustomModifierNode.exists_in(ctx, dataField, "index")
				if(isUnique && isIndex) {
					ctx.error("Data field cannot be both #unique and #index", dataField)
					return(fail)
				}
				if(isUnique) {
					%}
					v.addUniqueIndex("{%= fieldName %}")
					{%
				}
				if(isIndex) {
					%}
					v.addIndex("{%= fieldName %}")
					{%
				}
			}
		}
	%}
	return(v)
}

class MyIterator is Iterator<{%= className %}>
{
	prop iterator as SQLResultSetIterator

	func next as {%= className %}
	{
		if(iterator == null) {
			return(null)
		}
		var r = iterator.next()
		if(r == null) {
			return(null)
		}
		var v = new {%= className %}()
		v.importData(r)
		return(v)
	}
}

func queryRecordCount(database as SQLDatabase, tableName as string, callback as function<void,int>) static
{
	if(callback == null) {
		return
	}
	if(database == null) {
		callback(0)
		return
	}
	var stmt = database.prepareCountRecordsStatement(tableName, null)
	if(stmt == null) {
		callback(0)
		return
	}
	database.querySingleRow(stmt, func(result as DynamicMap) {
		if(result == null) {
			callback(0)
		}
		else {
			callback(result.getInteger("count"))
		}
	})
}

func queryAll(database as SQLDatabase, tableName as string, orderBy as array<SQLOrderingRule>, callback as function<void,Iterator<{%= className %}>>) static
{
	if(callback == null) {
		return
	}
	if(database == null) {
		callback(null)
		return
	}
	var stmt = database.prepareQueryAllStatement(tableName, [ {%= queryFields %} ], orderBy)
	if(stmt == null) {
		callback(null)
		return
	}
	database.query(stmt, func(results as SQLResultSetIterator) {
		if(results == null) {
			callback(null)
		}
		else {
			callback(new MyIterator().setIterator(results))
		}
	})
}

func queryPartial(database as SQLDatabase, tableName as string, offset as int, limit as int, orderBy as array<SQLOrderingRule>, callback as function<void,Iterator<{%= className %}>>) static
{
	if(callback == null) {
		return
	}
	if(database == null) {
		callback(null)
		return
	}
	var stmt = database.prepareQueryWithCriteriaStatement(tableName, null, limit, offset, [ {%= queryFields %} ], orderBy)
	if(stmt == null) {
		callback(null)
		return
	}
	database.query(stmt, func(results as SQLResultSetIterator) {
		if(results == null) {
			callback(null)
		}
		else {
			callback(new MyIterator().setIterator(results))
		}
	})
}

func insert(database as SQLDatabase, tableName as string, object as {%= className %}, callback as function<void,bool>) static
{
	if(database == null || object == null) {
		if(callback != null) {
			callback(false)
		}
		return
	}
	var data = new DynamicMap()
	object.exportData(data)
	var stmt = database.prepareInsertStatement(tableName, data)
	if(stmt == null) {
		if(callback != null) {
			callback(false)
		}
		return
	}
	database.execute(stmt, callback)
}

{% if(String.isEmpty(primaryKeyName) == false) { %}

	func update(database as SQLDatabase, tableName as string, object as {%= className %}, callback as function<void,bool>) static
	{
		if(database == null || object == null) {
			if(callback != null) {
				callback(false)
			}
			return
		}
		var data = new DynamicMap()
		object.exportData(data, false)
		var stmt = database.prepareUpdateStatement(tableName, DynamicMap.forMap({ "{%= primaryKeyName %}" : String.asString(object.{%= StringUtil.combineCamelCase([ "get", primaryKeyName ]) %}()) }), data)
		if(stmt == null) {
			if(callback != null) {
				callback(false)
			}
			return
		}
		database.execute(stmt, callback)
	}

	func delete(database as SQLDatabase, tableName as string, object as {%= className %}, callback as function<void,bool>) static
	{
		if(object == null) {
			if(callback != null) {
				callback(false)
			}
			return
		}
		{%= StringUtil.combineCamelCase([ "delete", "by", primaryKeyName ]) %}(database, tableName, object.{%= StringUtil.combineCamelCase([ "get", primaryKeyName ]) %}(), callback)
	}

{% } %}

{%
	foreach(dataField in dataFields) {
		var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
		var dataType = dataField.getType(ctx)
		var hadIndex = false
		if(CustomModifierNode.exists_in(ctx, dataField, "unique") || CustomModifierNode.exists_in(ctx, dataField, "primary")) {
			hadIndex = true
			%}
				func {%= StringUtil.combineCamelCase([ "query", "by", fieldName ]) %}(database as SQLDatabase, tableName as string, {%= fieldName %} as {%= sam.sling.SlingSourceOutput.dataTypeToString(ctx, dataType) %}, callback as function<void,{%= className %}>) static
				{
					if(callback == null) {
						return
					}
					if(database == null) {
						callback(null)
						return
					}
					var stmt = database.prepareQueryWithCriteriaStatement(tableName, { "{%= fieldName %}" : String.asString({%= fieldName %}) }, 1)
					if(stmt == null) {
						callback(null)
						return
					}
					database.querySingleRow(stmt, func(result as DynamicMap) {
						if(result == null) {
							callback(null)
						}
						else {
							var v = new {%= className %}()
							v.importData(result)
							callback(v)
						}
					})
				}
			{%
		}
		else if(CustomModifierNode.exists_in(ctx, dataField, "index")) {
			hadIndex = true
			%}
				func {%= StringUtil.combineCamelCase([ "query", "by", fieldName ]) %}(database as SQLDatabase, tableName as string, {%= fieldName %} as {%= sam.sling.SlingSourceOutput.dataTypeToString(ctx, dataType) %}, offset as int, limit as int, orderBy as array<SQLOrderingRule>, callback as function<void,Iterator<{%= className %}>>) static
				{
					if(callback == null) {
						return
					}
					if(database == null) {
						callback(null)
						return
					}
					var stmt = database.prepareQueryWithCriteriaStatement(tableName, { "{%= fieldName %}" : String.asString({%= fieldName %}) }, limit, offset, [ {%= queryFields %} ], orderBy)
					if(stmt == null) {
						callback(null)
						return
					}
					database.query(stmt, func(results as SQLResultSetIterator) {
						if(results == null) {
							callback(null)
						}
						else {
							callback(new MyIterator().setIterator(results))
						}
					})
				}

				func {%= StringUtil.combineCamelCase([ "query", "all", "unique", fieldName, "values" ]) %}(database as SQLDatabase, tableName as string, callback as function<void,DynamicIterator>) static
				{
					if(callback == null) {
						return
					}
					if(database == null) {
						callback(null)
						return
					}
					var stmt = database.prepareQueryDistinctValuesStatement(tableName, "{%= fieldName %}")
					if(stmt == null) {
						callback(null)
						return
					}
					database.query(stmt, func(results as SQLResultSetIterator) {
						if(results == null) {
							callback(null)
							return
						}
						callback(new SQLResultSetSingleColumnIterator().setColumnName("{%= fieldName %}").setIterator(results))
					})
				}

				func {%= StringUtil.combineCamelCase([ "query", "count", "for", fieldName ]) %}(database as SQLDatabase, tableName as string, {%= fieldName %} as {%= sam.sling.SlingSourceOutput.dataTypeToString(ctx, dataType) %}, callback as function<void,int>) static
				{
					if(callback == null) {
						return
					}
					if(database == null) {
						callback(0)
						return
					}
					var stmt = database.prepareCountRecordsStatement(tableName, { "{%= fieldName %}" : String.asString({%= fieldName %}) })
					if(stmt == null) {
						callback(0)
						return
					}
					database.querySingleRow(stmt, func(result as DynamicMap) {
						if(result == null) {
							callback(0)
						}
						else {
							callback(result.getInteger("count"))
						}
					})
				}
			{%
		}
		if(hadIndex) {
			%}
				func {%= StringUtil.combineCamelCase([ "delete", "by", fieldName ]) %}(database as SQLDatabase, tableName as string, {%= fieldName %} as {%= sam.sling.SlingSourceOutput.dataTypeToString(ctx, dataType) %}, callback as function<void,bool>) static
				{
					if(database == null) {
						if(callback != null) {
							callback(false)
						}
						return
					}
					var stmt = database.prepareDeleteStatement(tableName, DynamicMap.forMap({ "{%= fieldName %}" : String.asString({%= fieldName %}) }))
					if(stmt == null) {
						if(callback != null) {
							callback(false)
						}
						return
					}
					database.execute(stmt, callback)
				}
			{%
		}
	}
%}
