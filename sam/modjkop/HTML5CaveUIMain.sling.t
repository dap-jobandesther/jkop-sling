
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

func main(args as array<string>) static as int #main
{
	var context = new cave.GuiApplicationContextForHTML()
	var resources = [
		{%
		var project = SoftwareProjectNode.findProject(ctx, decl)
		if(project != null) {
			var first = true
			foreach(resourceNode as SoftwareProjectResourceNode in project.getResources(ctx)) {
				if(first == false) {
					%}, {%
				}
				%}"{%= resourceNode.getName(ctx) %}"{%
				first = false
			}
		}
		%}
	]
	context.prepareResources(resources, func {
		new {%= className %}().initialize()
	})
	return(0)
}
