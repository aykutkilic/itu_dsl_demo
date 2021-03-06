/*
 * generated by Xtext 2.23.0
 */
package tr.edu.itu.ce.demo.generator

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import tr.edu.itu.ce.demo.protocolDSl.Message
import tr.edu.itu.ce.demo.protocolDSl.Protocol

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class ProtocolDSlGenerator extends AbstractGenerator {
	@Inject ProtocolDSLCGenerator cgen
	@Inject ProtocolDSLPythonGenerator pygen
	
	override void doGenerate(
		Resource resource,
		IFileSystemAccess2 fsa,
		IGeneratorContext context
	) {
		fsa.generateFile('Makefile', cgen.generateMakefile(resource.contents.head as Protocol))
		fsa.generateFile('Compiler.h', cgen.generateCompilerH())
		
		val protocol = resource.contents.head as Protocol
		if(protocol !== null)
			fsa.generateFile('suite.py', pygen.generateTestSuite(protocol))

		var messages = resource.allContents.filter(Message).toList
		messages.forEach [
			fsa.generateFile(it.name + '.h', cgen.generateMessageCHeader(it))
			fsa.generateFile(it.name + '.c', cgen.generateMessageCSource(it))
			fsa.generateFile(it.name + '.py', pygen.generateMessagePyModule(it))
			fsa.generateFile(it.name + '_test.py', pygen.generateUnitTest(it))
		]
	}
}
