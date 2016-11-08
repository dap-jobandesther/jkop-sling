
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

class name IOSMain depends "objc-header-m:<UIKit/UIKit.h>" depends "objc-framework:UIKit":

class MyAppDelegate implements !"UIApplicationDelegate" depends "objc-header-h:<UIKit/UIKit.h>" imports cape
{
	var window protected as !"UIWindow*"
	var viewController protected as !"UIViewController*"
	var ctx protected as LoggingContext

	ctor
	{
		ctx = new cave.GuiApplicationContextForIOS()
	}

	func applicationDidFinishLaunching(application as !"UIApplication*")
	{
		Log.debug(ctx, "applicationDidFinishLaunching")
		lang "objc" {{{
			window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		}}}
		var cc = new {%= className %}()
		if(cc is cave.ScreenWithContext) {
			cc.setContext(ctx)
		}
		viewController = cc
		lang "objc" {{{
			window.rootViewController = self->viewController;
		}}}
		lang "objc" {{{
			[window makeKeyAndVisible];
		}}}
	}

	func applicationDidBecomeActive(application as !"UIApplication*")
	{
		Log.debug(ctx, "applicationDidBecomeActive")
	}

	func applicationWillResignActive(application as !"UIApplication*")
	{
		Log.debug(ctx, "applicationWillResignActive")
	}

	func applicationDidEnterBackground(application as !"UIApplication*")
	{
		Log.debug(ctx, "applicationDidEnterBackground")
	}

	func applicationWillEnterForeground(application as !"UIApplication*")
	{
		Log.debug(ctx, "applicationWillEnterForeground")
	}
}

func main(args as array<string>) static as int #main
{
	lang "objc" {{{
		@autoreleasepool {
			extern int _sling_argc;
			extern char** _sling_argv;
			return UIApplicationMain(_sling_argc, _sling_argv, nil, NSStringFromClass([IOSMainMyAppDelegate class]));
		}
	}}}
	return(0);
}
