package tr.edu.itu.ce.demo.generator

import java.util.Date
import javax.inject.Inject
import tr.edu.itu.ce.demo.protocolDSl.Message
import tr.edu.itu.ce.demo.protocolDSl.Protocol

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
		
		
		class PingMsg:
		    def __init__(self):
		        self.HDR = []
		        self.CSUM = 0
		    
		class PingMsgRx:
		    RX_ST_HDR = 0
		    RX_ST_CSUM = 1
		
		    def __init__(self):
		        self.__reset()
		
		    def __reset(self):
		        self.buffer = deque()
		        self.msg = PingMsg()    
		
		        self.state = PingMsgRx.RX_ST_HDR
		        self.state_i = 0
		        self.calc_csum = 0
		        
		    def on_rx(self, data):
		        self.buffer.append(data)
		        self.state_i+=1
		
		        if self.state == PingMsgRx.RX_ST_HDR:
		            expected = [0xDE, 0xAD]
		            if not data == expected[self.state_i-1]:
		                self.__reset()
		                return None
		
		            self.msg.HDR.append(data)
		
		            if self.state_i>=2:
		                self.state = PingMsgRx.RX_ST_CSUM
		
		        elif self.state == PingMsgRx.RX_ST_CSUM:
		            self.msg.CSUM = (self.msg.CSUM << 8 | data) & 0xFF
		            if self.state_i>=1:
		                if self.msg.CSUM!= self.calc_csum:
		                    self.__reset()
		                    return None
		
		                return self.msg
		
		        self.calc_csum += data
		        self.calc_csum &= 0xFF
		
		        return None
	'''
}
