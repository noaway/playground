<!doctype html>
<html>
	<head>
		<title>Noaway play</title>
		<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=0" />
		<link rel="stylesheet" href="/static/style.css">
		<link href="/static/prism.css" rel="stylesheet" />
	</head>
	<body>
		<div id="banner">
            <div id="head"><img src="/static/head.png" width="100" alt=""></div>
			<div id="controls">
				<input type="button" value="Run" id="run">
				<input type="button" value="Format" id="fmt">
				{{if $.Share}}
				<input type="button" value="Share" id="share">
				<input type="text" id="shareURL">
				<label id="embedLabel" style="display:none">
					<input type="checkbox" id="embed">
					embed
				</label>
				{{end}}
			</div>
		</div>
		<div id="wrap">
			<pre class="editor-pre line-numbers language-go"><code id="pre"></code></pre>
			<textarea class="editor" id="code" autocapitalize="off" autofocus="" spellcheck="false" autocomplete="off" autocorrect="off">{{printf "%s" .Snippet.Body}}</textarea>
		</div>
	<div id="output"></div>
	</body>
	<script src="/static/jquery.min.js"></script>
	<script src="/static/playground.js"></script>
	<script src="/static/prism.js"></script>
	<script>
		$(document).ready(function() {
			playground({
				'codeEl':       '#code',
				'outputEl':     '#output',
				'runEl':        '#run, #embedRun',
				'fmtEl':        '#fmt',
				'shareEl':      '#share',
				'shareURLEl':   '#shareURL',
				'enableHistory': true,
				'enableShortcuts': true,
				'enableVet': true
			});
		
			{{if .Analytics}}
			$('#run').click(function() {
				gtag('event', 'click', {
					event_category: 'playground',
					event_label: 'run-button',
				});
			});
			$('#share').click(function() {
				gtag('event', 'click', {
					event_category: 'playground',
					event_label: 'share-button',
				});
			});
			{{end}}

			var pre = document.getElementById('pre');
			var editorContent = document.getElementById('code');
			copy(pre, editorContent); 
			editorContent.addEventListener('input', function () {
				copy(pre, editorContent)
			});
			
			var autoExpand = function (field) {
				field.style.height = 'inherit';
				var computed = window.getComputedStyle(field);
				var height = parseInt(computed.getPropertyValue('border-top-width'), 10)
							+ parseInt(computed.getPropertyValue('padding-top'), 10)
							+ field.scrollHeight
							+ parseInt(computed.getPropertyValue('padding-bottom'), 10)
							+ parseInt(computed.getPropertyValue('border-bottom-width'), 10);
				field.style.height = height + 'px';
			};

			document.addEventListener('input', function (event) {
				if (event.target.tagName.toLowerCase() !== 'textarea') return;
				autoExpand(event.target);
			}, false);					
			
			function copy(pre, editor) {
				pre.innerText = editor.value;
				Prism.highlightElement(pre);
			};
		});
	</script>
</html>
