(defparameter *small* 1)
(defparameter *big* 100)

(defun guess-my-number ()
  (ash (+ *small* *big*) -1))

(defun smaller()
  (setf *big* (- (guess-my-number) 1))
   (guess-my-number))
  
(defun bigger()
  (setf *small* (+ (guess-my-number) 1))
   (guess-my-number))

(defun start-over()
  (defparameter *small* 1)
  (defparameter *big* 100)
  (guess-my-number))