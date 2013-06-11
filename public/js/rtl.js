//source: www.frequency-decoder.com/demo/detect-text-direction/


// This is the function that does all the hard work.
// Just pass a form element element (or array of form elements) to the 
// i18n.addElements method.
// The idea and regular expressions originally located within the goog.i18n.bidi 

// Javascript library (http://code.google.com/apis/gadgets/docs/i18n.html) and I

// take no credit what-so-ever for the idea.

var ltrChars = 'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF'+'\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF',
    rtlChars = '\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC',
    ltrDirCheckRe       = new RegExp('^[^'+rtlChars+']*['+ltrChars+']'),
    rtlDirCheckRe       = new RegExp('^[^'+ltrChars+']*['+rtlChars+']');

function checkDirection(elem) {
  var text = elem.value;                 
  elem.dir = isRtlText(text) ? 'rtl' : (isLtrText(text) ? 'ltr' : '');    
}

function isRtlText(text) {
  return rtlDirCheckRe.test(text);
}

function isLtrText(text) {
  return ltrDirCheckRe.test(text);
}
