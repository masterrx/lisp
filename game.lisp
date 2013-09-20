(defparameter *nodes* '((living-room (you are in the living-room.
                                          a wizard is snoring loudly on the couch.))
                        (garden (you are in a beatiful garden.
                                     	  there is a well in front of you.))
                        (attic (you are in the attic.
                        		          there is a giant welding torch in the corner.))))

(defparameter *edges* '((living-room (garden west door)
                                     (attic upstairs ladder))
                        (garden (living-room east door))
                        (attic (living-room downstairs ladder))))

(defparameter *objects* '(whiskey bucket frog chain))
(defparameter *object-locations* '((whiskey living-room)
                                   (bucket living-room)
                                   (chain garden)
                                   (frog garden)))

(defparameter *location* 'living-room)

(defparameter *allowed-commands* '(look walk pickup inventory))

(defun describe-location(location nodes)
  (cadr (assoc location nodes)))

(defun describe-path(edge)
	`(there is a ,(caddr edge) going ,(cadr edge) from here.))

(defun describe-paths(location edges)
  (apply #'append (mapcar #'describe-path(cdr(assoc location edges)))))

(defun objects-at(location objects object-locations)
  (labels ((at-loc-p (object)
                (eq (cadr (assoc object object-locations)) location)))
    (remove-if-not #'at-loc-p objects)))

(defun describe-objects(location objects object-locations)
  (labels ((describe-object (object)
                `(you see a ,object on the floor.)))  
  (apply #'append (mapcar #'describe-object(objects-at location objects object-locations)))))

(defun look()
  (append (describe-location *location* *nodes*)
  	      (describe-paths *location* *edges*)
  		  (describe-objects *location* *objects* *object-locations*)))

(defun walk(direction)
  (let ((next (find direction
                    (cdr (assoc *location* *edges*))
                    :key #'cadr)))
  (if next 
      (progn (setf *location* (car next))
             (look))
      '(You cannot go that way.))))

(defun pickup(object)
  (cond ((member object 
                 (objects-at *location* *objects* *object-locations*))
         (push (list object 'body) *object-locations*)
         `(you are now carrying the object))
  		 (t '(you cannot get that.))))

(defun inventory()
  (cons 'items(objects-at 'body *objects* *object-locations*)))

(defun game-repl()
  (let ((cmd (game-read)))
    (print cmd)
    (unless (eq(car cmd) 'quit)
      (game-print (game-eval cmd))
      (game-repl))))

(defun game-read()
  (let ((cmd(read-from-string
              (concatenate 'string "(" (read-line) ")" ))))
    (flet ((quote-it (x)
                     (list 'quote x)))
          (cons (car cmd) (mapcar #'quote-it (cdr cmd))))))

(defun game-eval(sexp)
  (if (member (car sexp) *allowed-commands*)
      (eval sexp)
      '(Unknown command.)))

(defun tweak-text (lst caps lit)
  (when lst
  (let ((item (car lst))
    	(rest (cdr lst)))
  (cond ((eql item #\space) (cons item (tweak-text rest caps lit)))
        ((member item '(#\! #\? #\.)) (cons item (tweak-text rest t lit)))
        ((eql item #\") (tweak-text rest caps (not lit)))
        (lit (cons item (tweak-text rest nil lit )))
        (caps (cons (char-upcase item) (tweak-text rest nil lit)))        
  		(t (cons (char-downcase item) (tweak-text rest nil nil)))))))

(defun game-print (lst)
  (princ (coerce (tweak-text (coerce (string-trim "()" (prin1-to-string lst))
                                     'list)
                             t 
                             nil)
                 'string))
  (fresh-line))

;(game-repl)

(defun dot-name(exp)
  (substitute-if #\_ (complement #'alphanumericp) (prin1-to-string exp)))

(defparameter *max-label-length* 30)

(defun dot-label (exp)
   (if exp
       (let ((s (write-to-string exp :pretty nil)))
         (if (> (length s) *max-label-length*)
             (concatenate 'string (subseq s 0 (- *max-label-length* 3)) "...")
             s))
       ""))

(defun nodes->dot (nodes)
  (mapc (lambda(node)
          (fresh-line)
          (princ (dot-name (car node)))
          (princ "[label=\"")
          (princ (dot-label node))
          (princ "\"];"))
        nodes)) 

(defun edges->dot (edges)
  (mapc (lambda(node)
    (mapc (lambda(edge)
            (fresh-line)
            (princ (dot-name (car node)))
            (princ "->")
            (princ (dot-name (car edge)))
            (princ "[label=\"")
            (princ (dot-label (cdr edge)))
            (princ "\"];"))
          (cdr node)))
        edges))

(defun graph-dot(nodes edges)
  (princ "digraph{")
  (nodes->dot nodes)
  (edges->dot edges)
  (princ "}"))

(defun dot->png(fname thunk)
  (with-open-file( *standard-output*
                   fname
                   :direction :output
                   :if-exists :supersede)                                   
                  (funcall thunk))
  (ext:shell (concatenate 'string "C:\\Program Files (x86)\\Graphviz2.34\\bin\\neato.exe -Tpng -O " fname))()
)

(defun graph->png (fname nodes edges)
  (dot->png fname 
            (lambda()
              (graph-dot nodes edges))))
         
;(graph->png "C:\\Users\\Guenterc\\Documents\\lisp\\test.dot" *nodes* *edges*)

(defun uedges->dot (edges)
  (maplist (lambda (lst)
             (mapc (lambda (edge)
                  (unless (assoc (car edge) (cdr lst))
                      (fresh-line)
                       (princ (dot-name (caar lst)))
                       (princ "--")
                       (princ (dot-name (car edge)))
                       (princ "[label=\"")
                       (princ (dot-label (cdr edge)))
                       (princ "\"];")))
                   (cdar lst)))
           edges))

(defun ugraph->dot (nodes edges) 
  (princ "graph{")
  (nodes->dot nodes)
  (uedges->dot edges)
  (princ "}"))

(defun ugraph->png (fname nodes edges)
  (dot->png fname
            (lambda ()
              (ugraph->dot nodes edges))))

(ugraph->png "C:\\Users\\Guenterc\\Documents\\lisp\\test_ugraph2.dot" *nodes*  *edges*)