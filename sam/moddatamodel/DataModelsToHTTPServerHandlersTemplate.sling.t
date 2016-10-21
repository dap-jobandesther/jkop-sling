
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

func forDatabase(database as SQLDatabase, tableName as string) static as this
{
	var v = new this()
	v.setDatabase(database)
	v.setTableName(tableName)
	return(v)
}

prop database as SQLDatabase
prop tableName as string
prop recordsPerPage = 50

func initialize(server as HTTPServerBase) override
{
	base.initialize(server)
	if(database != null || tableName != null) {
		database.ensureTableExists({%= className %}.SQL.getTableInfo(tableName))
	}
	get("", onGetAllRecords)
	{%
		foreach(dataField in dataFields) {
			var isPrimary = CustomModifierNode.exists_in(ctx, dataField, "primary")
			var isUnique =  CustomModifierNode.exists_in(ctx, dataField, "unique")
			var isIndex = CustomModifierNode.exists_in(ctx, dataField, "index")
			var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
			if(isPrimary || isUnique || isIndex) {
				if(isIndex) {
					%}
						get("{%= fieldName %}", {%= StringUtil.combineCamelCase([ "on", "get", fieldName, "list" ]) %})
					{%
				}
				%}
				get("{%= fieldName %}/*", func(req as HTTPServerRequest) {
					{%= StringUtil.combineCamelCase([ "on", "get", "by", fieldName ]) %}(req, req.popResource())
				})
				delete("{%= fieldName %}/*", func(req as HTTPServerRequest) {
					{%= StringUtil.combineCamelCase([ "on", "delete", "by", fieldName ]) %}(req, req.popResource())
				})
				{%
			}
			if(isPrimary || isUnique) {
				%}
					put("{%= fieldName %}/*", func(req as HTTPServerRequest) {
						{%= StringUtil.combineCamelCase([ "on", "replace", "by", fieldName ]) %}(req, req.popResource())
					})
				{%
			}
		}
	%}
	post("", onPostRecord)
}

func vectorForIterator(iterator as DynamicIterator) private as vector<object>
{
	if(iterator == null) {
		return(null)
	}
	var v = new vector<object>;
	loop {
		var o = iterator.nextString()
		if(o == null) {
			break
		}
		v += o
	}
	return(v)
}

func vectorForIterator(iterator as Iterator<{%= className %}>) private as vector<object>
{
	if(iterator == null) {
		return(null)
	}
	var v = new vector<object>;
	loop {
		var o = iterator.next()
		if(o == null) {
			break
		}
		var m = new DynamicMap()
		o.exportData(m)
		v += m
	}
	return(v)
}

func onGetAllRecords(req as HTTPServerRequest)
{
	var pp = 0
	var spage = req.getQueryParameter("page")
	if(spage != null) {
		pp = String.toInteger(spage) - 1
	}
	if(pp < 0) {
		pp = 0
	}
	{%= className %}.SQL.queryRecordCount(database, tableName, func(count as int) {
		var pages = count /  recordsPerPage;
		if(count % recordsPerPage > 0) {
			pages ++;
		}
		if(pages < 1) {
			pages = 1;
		}
		{% if(Vector.getSize(sortColumns) < 1) { %}
			var orderBy as array<SQLOrderingRule> = null
		{% }
		else { %}
			var orderBy = [ {%
				var first = true
				foreach(sortColumn in sortColumns) {
					if(first == false) {
						%}, {%
					}
					if(sortColumn.getDescending()) {
						%}SQLOrderingRule.forDescending("{%= sortColumn.getColumn() %}"){%
					}
					else {
						%}SQLOrderingRule.forAscending("{%= sortColumn.getColumn() %}"){%
					}
					first = false
				}
			%} ]
		{% } %}
		{%= className %}.SQL.queryPartial(database, tableName, pp * recordsPerPage, recordsPerPage, orderBy, func(results as Iterator<{%= className %}>) {
			if(results == null) {
				req.sendJSONObject(JSONResponse.forInternalError())
				return
			}
			var data = new DynamicMap()
			data.set("records", vectorForIterator(results))
			data.set("currentPage", pp+1)
			data.set("pageCount", pages)
			req.sendJSONObject(JSONResponse.forOk(data))
		})
	})
}

func onPostRecord(req as HTTPServerRequest)
{
	var data = req.getBodyJSONMap()
	if(data == null) {
		req.sendJSONObject(JSONResponse.forInvalidRequest())
		return
	}
	{% if(primaryKeyIsInteger) { %}
		data.remove("{%= primaryKeyName %}")
	{% } %}
	var object = new {%= className %}()
	object.importData(data)
	object.validate(func(error as string) {
		if(error != null) {
			req.sendJSONObject(JSONResponse.forErrorCode(error))
			return
		}
		{%= className %}.SQL.insert(database, tableName, object, func(status as bool) {
			if(status == false) {
				req.sendJSONObject(JSONResponse.forInternalError())
				return
			}
			req.sendJSONObject(JSONResponse.forOk())
		})
	})
}

{%
	foreach(dataField in dataFields) {
		var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
		var dataType = dataField.getType(ctx)
		var hadIndex = false
		if(CustomModifierNode.exists_in(ctx, dataField, "primary") || CustomModifierNode.exists_in(ctx, dataField, "unique")) {
			hadIndex = true
			%}
			func {%= StringUtil.combineCamelCase([ "on", "get", "by", fieldName ]) %}(req as HTTPServerRequest, {%= fieldName %} as string)
			{
				{% if(dataType is StringDataTypeNode) { %}
					var dd = {%= fieldName %}
				{% } %}
				{% if(dataType is IntegerDataTypeNode) { %}
					var dd = String.toInteger({%= fieldName %})
				{% } %}
				{%= className %}.SQL.{%= StringUtil.combineCamelCase([ "query", "by", fieldName ]) %}(database, tableName, dd, func(record as {%= className %}) {
					if(record == null) {
						req.sendJSONObject(JSONResponse.forNotFound())
						return
					}
					var adata = new DynamicMap()
					record.exportData(adata)
					req.sendJSONObject(JSONResponse.forOk(adata))
				})
			}

			func {%= StringUtil.combineCamelCase([ "on", "replace", "by", fieldName ]) %}(req as HTTPServerRequest, {%= fieldName %} as string)
			{
				var data = req.getBodyJSONMap()
				if(data == null) {
					req.sendJSONObject(JSONResponse.forInvalidRequest())
					return
				}
				{% if(dataType is StringDataTypeNode) { %}
					var dd = {%= fieldName %}
				{% } %}
				{% if(dataType is IntegerDataTypeNode) { %}
					var dd = String.toInteger({%= fieldName %})
				{% } %}
				var record = new {%= className %}()
				record.importData(data)
				record.{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(dd)
				record.validate(func(error as string) {
					if(error != null) {
						req.sendJSONObject(JSONResponse.forErrorCode(error))
						return
					}
					{%= className %}.SQL.update(database, tableName, record, func(status as bool) {
						if(status == false) {
							req.sendJSONObject(JSONResponse.forInternalError())
							return
						}
						req.sendJSONObject(JSONResponse.forOk())
					})
				})
			}
			{%
		}
		else if(CustomModifierNode.exists_in(ctx, dataField, "index")) {
			hadIndex = true
			%}
				func {%= StringUtil.combineCamelCase([ "on", "get", fieldName, "list" ]) %}(req as HTTPServerRequest)
				{
					{%= className %}.SQL.{%= StringUtil.combineCamelCase([ "query", "all", "unique", fieldName, "values" ]) %}(database, tableName, func(results as DynamicIterator) {
						if(results == null) {
							req.sendJSONObject(JSONResponse.forInternalError())
							return
						}
						req.sendJSONObject(JSONResponse.forOk(vectorForIterator(results)))
					})
				}

				func {%= StringUtil.combineCamelCase([ "on", "get", "by", fieldName ]) %}(req as HTTPServerRequest, {%= fieldName %} as string)
				{
					{% if(dataType is StringDataTypeNode) { %}
						var dd = {%= fieldName %}
					{% } %}
					{% if(dataType is IntegerDataTypeNode) { %}
						var dd = String.toInteger({%= fieldName %})
					{% } %}
					var pp = 0
					var spage = req.getQueryParameter("page")
					if(spage != null) {
						pp = String.toInteger(spage) - 1
					}
					if(pp < 0) {
						pp = 0
					}
					{%= className %}.SQL.{%= StringUtil.combineCamelCase([ "query", "count", "for", fieldName ]) %}(database, tableName, dd, func(count as int) {
						var pages = count /  recordsPerPage;
						if(count % recordsPerPage > 0) {
							pages ++;
						}
						if(pages < 1) {
							pages = 1;
						}
						{% if(Vector.getSize(sortColumns) < 1) { %}
							var orderBy as array<SQLOrderingRule> = null
						{% }
						else { %}
							var orderBy = [ {%
								var first = true
								foreach(sortColumn in sortColumns) {
									if(first == false) {
										%}, {%
									}
									if(sortColumn.getDescending()) {
										%}SQLOrderingRule.forDescending("{%= sortColumn.getColumn() %}"){%
									}
									else {
										%}SQLOrderingRule.forAscending("{%= sortColumn.getColumn() %}"){%
									}
									first = false
								}
							%} ]
						{% } %}
						{%= className %}.SQL.{%= StringUtil.combineCamelCase([ "query", "by", fieldName ]) %}(database, tableName, dd, pp * recordsPerPage, recordsPerPage, orderBy, func(results as Iterator<{%= className %}>) {
							if(results == null) {
								req.sendJSONObject(JSONResponse.forInternalError())
								return
							}
							var data = new DynamicMap()
							data.set("records", vectorForIterator(results))
							data.set("{%= fieldName %}", {%= fieldName %})
							data.set("currentPage", pp+1)
							data.set("pageCount", pages)
							req.sendJSONObject(JSONResponse.forOk(data))
						})
					})
				}
			{%
		}
		if(hadIndex) {
			%}
				func {%= StringUtil.combineCamelCase([ "on", "delete", "by", fieldName ]) %}(req as HTTPServerRequest, {%= fieldName %} as string)
				{
					{% if(dataType is StringDataTypeNode) { %}
						var dd = {%= fieldName %}
					{% } %}
					{% if(dataType is IntegerDataTypeNode) { %}
						var dd = String.toInteger({%= fieldName %})
					{% } %}
					{%= className %}.SQL.{%= StringUtil.combineCamelCase([ "delete", "by", fieldName ]) %}(database, tableName, dd, func(status as bool) {
						if(status == false) {
							req.sendJSONObject(JSONResponse.forInternalError())
							return
						}
						req.sendJSONObject(JSONResponse.forOk())
					})
				}
			{%
		}
	}
%}
