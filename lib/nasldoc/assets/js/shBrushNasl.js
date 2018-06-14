(function()
{
	typeof(require) != 'undefined' ? SyntaxHighlighter = require('shCore').SyntaxHighlighter : null;

	function Brush()
	{
		var constants	= 'FALSE NULL TRUE';

		var keywords	= 'break continue else export for foreach function global_var if ' +
				  'import include local_var repeat return until while namespace object ' +
                                  'var public private case switch default do';

		this.regexList = [
			{ regex: SyntaxHighlighter.regexLib.singleLinePerlComments,		css: 'comment' },

			{ regex: SyntaxHighlighter.regexLib.doubleQuotedString,			css: 'string' },
			{ regex: SyntaxHighlighter.regexLib.singleQuotedString,			css: 'string' },
			{ regex: new RegExp('\\b[0-9]+\\b', 'gm'),				css: 'number' },

			{ regex: new RegExp(this.getKeywords(constants), 'gm'),			css: 'constant' },
			{ regex: new RegExp(this.getKeywords(keywords), 'gm'),			css: 'keyword' },

			{ regex: new RegExp('\\b[A-Za-z_][A-Za-z0-9_]*\\b(?=\\s*\\()', 'gm'),	css: 'function' },
			{ regex: new RegExp('\\b[A-Za-z_][A-Za-z0-9_]*\\b(?!\\s*\\()', 'gm'),	css: 'variable' }
		];
	};

	Brush.prototype	= new SyntaxHighlighter.Highlighter();
	Brush.aliases	= ['nasl'];

	SyntaxHighlighter.brushes.Nasl = Brush;

	typeof(exports) != 'undefined' ? exports.Brush = Brush : null;
})();
