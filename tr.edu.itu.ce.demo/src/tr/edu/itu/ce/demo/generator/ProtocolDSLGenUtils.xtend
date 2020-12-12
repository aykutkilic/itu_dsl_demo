package tr.edu.itu.ce.demo.generator

import tr.edu.itu.ce.demo.protocolDSl.Entry
import tr.edu.itu.ce.demo.protocolDSl.Message
import org.eclipse.xtext.EcoreUtil2

class ProtocolDSLGenUtils {
	def parent_msg(Entry e) { e.eContainer as Message }

	def parent_msg_name(Entry e) '''«e.parent_msg.name»'''
	
	def c_hex(String value) '''0x«value.substring(0,value.length-1)»'''
	
	def next(Entry e) { EcoreUtil2.getNextSibling(e) as Entry }	
}