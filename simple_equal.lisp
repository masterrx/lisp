(print (eq 1 2))
(print (eq 1 1))
(princ "Test String")
(print "Test String die 2.")
(print '(expt 3 (expt 3 9)))
(print (cons 'chicken 'cat))
(print (cons 'chicken ()))
(print (cons 'pork '(chicken beef)))
(let ((x '(pork chicken beef)))
	(print (car x))
 	(print (cdr x)))
(print (cadr '((peas carrots tomatoes)(pork beef chicken))))