package tr.edu.itu.ce.demo.generator

import java.util.Date
import javax.inject.Inject
import tr.edu.itu.ce.demo.protocolDSl.Message
import tr.edu.itu.ce.demo.protocolDSl.Protocol
import tr.edu.itu.ce.demo.protocolDSl.Csum
import tr.edu.itu.ce.demo.protocolDSl.Entry
import tr.edu.itu.ce.demo.protocolDSl.Spec
import tr.edu.itu.ce.demo.protocolDSl.BitMask
import tr.edu.itu.ce.demo.protocolDSl.EnumSpec
import tr.edu.itu.ce.demo.protocolDSl.BitRegion

class ProtocolDSLPythonGenerator {
	@Inject extension ProtocolDSLGenUtils utils
	
	def generateMessagePyModule(Message msg) '''
		# -------------------------------------------------------------
		# Protocol «(msg.eContainer as Protocol).name»
		# Message  «msg.name»
		# Date     «new Date(System.currentTimeMillis)»
		# 
		# Generated code. Please do not modify.
		# -------------------------------------------------------------
		
		from collections import deque
		«FOR bm : msg.entries.filter(BitMask)»
			«bm.generateClass»
		«ENDFOR»
		
		«FOR e : msg.entries.filter(EnumSpec)»
			«e.generateClass»
		«ENDFOR»
		
		class «msg.msgClassName»:
			def __init__(self):
				«FOR e : msg.entries»
					self.«e.name.toPyName»= «e.initValue»
				«ENDFOR»
		
		class «msg.rxClassName»:
			«msg.generateRxStateEntries»
		
			def __init__(self):
				self.__reset()
		
			def __reset(self):
				self.buffer = deque()
				self.msg = «msg.msgClassName»()
		
				self.state = «msg.rxClassName».RX_ST_HDR
				self.state_i = 0
				«FOR csum : msg.entries.filter(Csum)»
					«csum.calcCsumName» = 0
				«ENDFOR»
		
			def on_rx(self, data):
				self.buffer.append(data)
				self.state_i += 1
				
				«FOR csum : msg.entries.filter(Csum)»
				if self.state < «csum.rxStateSelector»:
					«csum.calcCsumName» += data
					«csum.calcCsumName» &= «csum.type.typeMask»
				«ENDFOR»
				
				«FOR i : 0..msg.entries.length-1»
				«if(i==0) 'if' else 'elif'» self.state == «msg.entries.get(i).rxStateSelector»:
					«msg.entries.get(i).generateMatcher»
					«msg.entries.get(i).generateTransition»
				«ENDFOR»
		
				return None
	'''
	
	def generateRxStateEntries(Message msg) '''
		«FOR e : msg.entries.withIndex»
		«e.first.rxStateName» = «e.second»
		«ENDFOR»
	'''
	
	def dispatch generateClass(BitMask bm) '''
		class «bm.name.toPyName»:
			def __init__(self, data):
				«FOR r : bm.regions»
					«r.selector» = 0
				«ENDFOR»
			
			def from_data(data):
				«FOR rgn : bm.regions.accumulate(0, [r,i | i+r.width])»
					«rgn.first.selector» = data>>«rgn.second» & «rgn.first.mask»
				«ENDFOR»
		
			def to_data():
				return \
					«FOR rgn : bm.regions.accumulate(0, [r,i | i+r.width]) SEPARATOR ' | \\'»
						(«rgn.first.selector» & «rgn.first.mask») << «rgn.second»
					«ENDFOR»
	'''
	
	def dispatch generateClass(EnumSpec enm) '''
		class «enm.name.toPyName»:
			«FOR e : enm.entries.accumulate(0, 
				[e,v | if(e.value!==null) e.value.hex_value else v],
				[_,v | v+1])»
			«e.first.name» = «e.second»
			«ENDFOR»
	'''
	
	def dispatch generateMatcher(Entry e) '''
		«e.msgSelector».append(data)
	'''
	
	def generateTransition(Entry e) '''
		if self.state_i >= «e.size»:
			«val next = e.next»
			«IF next!==null»
			self.state = «next.rxStateSelector»
			self.state_i = 0
			«ELSE»
			return self.msg
			«ENDIF»
	'''
	def dispatch generateMatcher(Spec s) '''
		«IF s.value !== null»
		expected = [«FOR v : s.value.items SEPARATOR ','»«v.c_hex»«ENDFOR»]
		if not data == expected[self.state_i-1]:
			self.__reset()
			return None
        «ENDIF»
        «IF s.count>1»
			«s.msgSelector».append(data)
        «ELSE»
			«s.shiftLeftAndAssign»
        «ENDIF»
	'''
	
	def dispatch generateMatcher(Csum csum) '''
		«csum.shiftLeftAndAssign»
		if self.state_i >= «csum.size»:
			if «csum.msgSelector» != «csum.calcCsumName»:
				self.__reset()
				return None
	'''
	
	def dispatch initValue(Entry e) '''0'''
	def dispatch initValue(Spec s) '''«IF(s.count>0)»[]«ELSE»0«ENDIF»'''
	
	def shiftLeftAndAssign(Entry e) '''«e.msgSelector» = («e.msgSelector» << 8 | data) & «e.type.typeMask»'''
	def toPyName(BitRegion r) '''«r.name.toUpperCase»'''
	def selector(BitRegion r) '''self.«r.toPyName»'''
	
	def msgSelector(Entry e) '''self.msg.«e.name.toUpperCase»'''
	
	def rxStateName(Entry e) '''RX_ST_«e.name.toUpperCase»'''
	def rxStateSelector(Entry e) '''«e.parent_msg.rxClassName».RX_ST_«e.name.toUpperCase»'''
	def calcCsumName(Csum csum) '''self.calc_«csum.name.toLowerCase»'''
	def msgClassName(Message msg) '''«msg.name.toPyName»Msg'''
	def rxClassName(Message msg) '''«msg.name.toPyName»RxMsg'''
}
