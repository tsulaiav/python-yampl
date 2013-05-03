from libc.stdlib cimport malloc, free
from libcpp.string cimport string
from cython.operator cimport dereference as dereference
import pickle

cdef extern from "Python.h":
	char* PyBytes_AsString(object string)
	object PyBytes_FromStringAndSize(const char *, Py_ssize_t)

cdef extern from "Channel.h" namespace "yampl":
	cdef enum Context:
		THREAD = 0,
		LOCAL_SHM,
		LOCAL_PIPE,
		LOCAL,
		DISTRIBUTED

	cdef cppclass Channel:
		string name
		Context context
		Channel(const string&, Context)

cdef extern from "ISocket.h" namespace "yampl":
	cdef cppclass ISocket:
		void send(void *, size_t) except +
		size_t recv(void *&buffer) except +

cdef extern from "SocketFactory.h" namespace "yampl":
	cdef cppclass SocketFactory:
		ISocket *createClientSocket(Channel channel)
		ISocket *createServerSocket(Channel)

cdef class PySocket:
	cdef ISocket *socket
	cdef SocketFactory *factory
	cdef Channel *channel

	def __cinit__(self, name, context):
		self.socket = self.factory = self.channel = NULL
		decoded = name.encode("utf-8")
		cdef string *n = new string(<char*>decoded)
		cdef Context c

		context = context.upper()
		if context == "THREAD":
			c = THREAD
		elif context == "LOCAL_SHM":
			c = LOCAL_SHM
		elif context == "LOCAL_PIPE":
			c = LOCAL_PIPE
		elif context == "LOCAL":
			c = LOCAL
		elif context == "DISTRIBUTED":
			c = DISTRIBUTED
		else:
			raise NameError(context + " is not a valid contex")

		self.channel = new Channel(dereference(n), c)
		self.factory = new SocketFactory()

		del n

	def __dealloc__(self):
		del self.socket
		del self.channel
		del self.factory

	def send(self, message):
		pickled = pickle.dumps(message)
		self.socket.send(PyBytes_AsString(pickled), len(pickled));
		
	def send_raw(self, message):
		cdef char *msg = message
		self.socket.send(msg, len(message))

	def recv(self):
		cdef char *msg = NULL
		size = self.socket.recv(msg)
		obj = pickle.loads(PyBytes_FromStringAndSize(msg, size));
		free(msg)
		return (size, obj)

	def recv_raw(self):
		cdef char *msg = NULL
		size = self.socket.recv(msg)
		obj = PyBytes_FromStringAndSize(msg, size)
		return (size, obj)

cdef class ClientSocket(PySocket):
	def __cinit__(self, name, context):
		super().__init__(self, name, context)
		self.socket = self.factory.createClientSocket(dereference(self.channel))


cdef class ServerSocket(PySocket):
	def __cinit__(self, name, context):
		super().__init__(self, name, context)
		self.socket = self.factory.createServerSocket(dereference(self.channel))
