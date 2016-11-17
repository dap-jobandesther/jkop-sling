
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

func exportData(data as DynamicMap, includePrimaryKey as bool = true)
{
	if(data == null) {
		return
	}
	{% foreach(fn in onExportFunctionNames) { %}
		{%= fn %}()
	{% } %}
	{%
		var nullType = new NullDataTypeNode()
		foreach(dataField in dataFields) {
			var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
			var dataType = dataField.getType(ctx)
			var isPrimary = CustomModifierNode.exists_in(ctx, dataField, "primary")
			if(isPrimary) {
				if(dataType is IntegerDataTypeNode) {
					%}
						if(includePrimaryKey && {%= fieldName %} >= 0) {
							data.set("{%= fieldName %}", {%= fieldName %})
						}
					{%
				}
				else {
					%}
						if(includePrimaryKey) {
							data.set("{%= fieldName %}", {%= fieldName %})
						}
					{%
				}
			}
			else {
				if(dataType != null && dataType.matches(ctx, nullType, null)) {
					%}
						if({%= fieldName %} != null) {
							data.set("{%= fieldName %}", {%= fieldName %})
						}
					{%
				}
				else {
					%}
						data.set("{%= fieldName %}", {%= fieldName %})
					{%
				}
			}
		}
	%}
}

func importData(data as DynamicMap)
{
	if(data == null) {
		return
	}
	{%
		foreach(dataField in dataFields) {
			var fieldName = eq.api.String.as_strptr(dataField.getName(ctx))
			var dataType = dataField.getType(ctx)
			if(dataType is IntegerDataTypeNode) {
				%}
				{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(data.getInteger("{%= fieldName %}", {%= fieldName %}))
				{%
			}
			else if(dataType is StringDataTypeNode) {
				%}
				{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(data.getString("{%= fieldName %}", {%= fieldName %}))
				{%
			}
			else if(dataType is BufferDataTypeNode) {
				%}
				{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(data.getBuffer("{%= fieldName %}"))
				{%
			}
			else if(dataType is DoubleDataTypeNode) {
				%}
				{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(data.getDouble("{%= fieldName %}", {%= fieldName %}))
				{%
			}
			else {
				%}
				{%= StringUtil.combineCamelCase([ "set", fieldName ]) %}(data.get("{%= fieldName %}", {%= fieldName %}))
				{%
			}
		}
	%}
	{% foreach(fn in onImportFunctionNames) { %}
		{%= fn %}()
	{% } %}
}
