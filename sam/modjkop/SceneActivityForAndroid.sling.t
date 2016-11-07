
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

class name {%= className %}Activity is !"android.app.Activity" public imports cape imports cave imports motion #androidActivity #main
{
	var backend as BackendForAndroidView

	func onCreate(savedInstance as !"android.os.Bundle")
	{
		base.onCreate(savedInstance)
		var ctx = GuiApplicationContextForAndroid.forActivityContext(this)
		backend = BackendForAndroidView.forScene(new {%= className %}(), ctx)
		lang "java" {{{ setContentView(backend.getAndroidView()); }}}
	}

	func onResume
	{
		base.onResume()
		lang "java" {{{
			getWindow().setFlags(android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN, android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN);
			android.app.ActionBar ab = getActionBar();
			ab.hide();
		}}}
	}

	func onStart
	{
		base.onStart()
		backend.onStart()
	}

	func onStop
	{
		base.onStop()
		backend.onStop()
	}

	func onDestroy
	{
		base.onDestroy()
		backend.onDestroy()
		backend = null
	}
}
