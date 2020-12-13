package tr.edu.itu.ce.demo.generator

import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.util.Pair
import tr.edu.itu.ce.demo.protocolDSl.BitRegion
import tr.edu.itu.ce.demo.protocolDSl.Entry
import tr.edu.itu.ce.demo.protocolDSl.Message
import tr.edu.itu.ce.demo.protocolDSl.Spec
import java.util.List
import java.util.ArrayList
import org.eclipse.xtext.util.Tuples
import org.eclipse.xtext.xbase.lib.Functions.Function2

class ProtocolDSLGenUtils {
	def parent_msg(Entry e) { e.eContainer as Message }

	def parent_msg_name(Entry e) '''«e.parent_msg.name»'''

	def c_hex(String value) '''0x«value.substring(0,value.length-1)»'''

	def hex_value(String hex) {
		Integer.parseInt(hex.substring(0, hex.length - 1), 16)
	}

	def to_hex(Integer i) {
		'0x' + Integer.toHexString(i).toUpperCase
	}

	def next(Entry e) { EcoreUtil2.getNextSibling(e) as Entry }

	def dispatch size(Entry e) { e.type.typeSize }

	def dispatch size(Spec s) { s.type.typeSize * s.itemCount }

	def itemCount(Spec s) {
		if (s.count >= 1)
			s.count
		else if (s.value !== null)
			s.value.items.length
		else
			1
	}

	def typeSize(String type) {
		switch (type) {
			case 'u8',
			case 's8': 1
			case 'u16',
			case 's16': 2
			case 'u32',
			case 's32': 4
			case 'u64',
			case 's64': 8
		}
	}

	def typeMask(String type) {
		switch (type) {
			case 'u8',
			case 's8': '0xFF'
			case 'u16',
			case 's16': '0xFFFF'
			case 'u32',
			case 's32': '0xFFFFFFFF'
			case 'u64',
			case 's64': '0xFFFFFFFFFFFFFFFF'
		}
	}

	def mask(BitRegion br) {
		((1 << br.width) - 1).to_hex
	}

	def <T> List<Pair<T, Integer>> withIndex(List<T> original) {
		return original.accumulate(0, [_, i | i + 1])
	}
	
	def <T, R> List<Pair<T, R>> accumulate(List<T> original, R seed,
		Function2<? super T, ? super R, ? extends R> after) {
		return accumulate(original, seed, null, after)		
	}
	
	def <T, R> List<Pair<T, R>> accumulate(List<T> original, R seed,
		Function2<? super T, ? super R, ? extends R> before,
		Function2<? super T, ? super R, ? extends R> after) {
		
		val result = new ArrayList<Pair<T, R>>()
		var i = seed
		for (l : original) {
			if(before !== null)
				i = before.apply(l, i)
				
			result.add(Tuples.pair(l, i))
			
			if(after !== null)
				i = after.apply(l,i)
		}
		
		return result;
	}
}
