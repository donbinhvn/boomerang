require 'roo'
require 'yaml'
class CallSpec1
	attr_accessor :platform, :return,:param,:additionParam,:stackAlign,:scratch,:preserved,:callList
end

Test1 = Struct.new(:clgt)
CallSpec = Struct.new(:platform, :return,:param,:additionParam,:stackAlign,:scratch,:preserved,:callList) 
def restructure_data
	file = Roo::Spreadsheet.open('./CallSpec.ods')
	f = file.sheet(0) 
	callSpecs = []
	count = 0 
	f.each(platforms: 'Platform', returns:'Return Value', parameters:'Parameters', addparams:'Additional Parameters',align:'Stack Alignment',scratchs:'Scratch Registers',preserveds:'Preserved Registers',calls:'Call List') do |hash|
		if count != 0
			p1 = hash[:platforms]
			if hash[:returns].nil?
				hash[:returns] = ""
			end	
			p2 = hash[:returns].gsub(/\s+/, "").split(',')
			if hash[:parameters].nil?
				hash[:parameters]=""
			end
			p3 = hash[:parameters].gsub(/\s+/, "").split(',')
			#if hash[:addparams].nil?
			#	hash[:addparams]=""
			#end
			#p4 = hash[:addparams].gsub(/r\d+/,"").split(' ')
			p4 = hash[:addparams]
			p5 = hash[:align]
			p6 = hash[:scratchs]
			p7 = hash[:preserveds]
			p8 = hash[:calls]
			#temp = CallSpec.new(hash[:platforms],hash[:returns],hash[:parameters],hash[:addparams],hash[:align],hash[:scratchs],hash[:preserveds],hash[:calls])
			#
			temp = CallSpec.new(p1, p2, p3, p4, p5, p6, p7, p8)
			callSpecs<<temp
			
		end
		count=count +1
	end
	return callSpecs	
end
def code_generation (specification)
	#print specification 
	#print "\n"
	#indent = 0
	code = ""
	##WRITING CODE HERE
	
	code<<"switch (prog->getFrontEndId()){\n" ##switch machine architecture
	index=0
	for machine in specification
		index=index+1
		code<<"\tcase #{machine[:platform]}:{\n"
		for i in 1..machine[:param].length
			code<<"\tbool param#{index}#{i} = false;\n"
		end
		code<<"\tbool ispara#{index} = false;\n";
		code<<"\tbool addparam#{index} = false;"
		i=1
		code<<"\tfor (stit = stmts.begin(); stit != stmts.end(); ++stit) {\n" #check each STMT
		code<<"\t\tStatement* s = *stit;\n"
		code<<"\t\tispara#{index}=false;\n"
		code<<"\t\tif(!s->isAssignment())\n"# Break if not an assignment
		code<<"\t\t\tcontinue;\n"
		code<<"\t\tExp *lhs = ((Assignment*)s)->getLeft();\n"
		for reg in machine[:param] ## process parameter
			code<<"\t\tif(((std::string)lhs->prints())==\"#{reg}\"){\n"## process parameter using switch case
			code<<"\t\t\tispara#{index} = true;\n"
			code<<"\t\t\tparam#{index}#{i} = true;\n"
			code<<"\t\t}\n"
			i=i+1;
		end       ##end process parameter
		if !machine[:additionParam].nil?## Handle addition paramater on register x
			code<<"\t\tif("
			#check for all official params first
			for i in 1..machine[:param].length
				code<<"param#{index}#{i} && "
			end
			code<<"!addparam#{index}){\n"
			code<<"\t\t\tstit = stmts.begin();\n"
			code<<"\t\t\tc->ABIparameters.clear();\n"
			code<<"\t\t\taddparam#{index} = true;\n"
			code<<"\t\t}\n"
			code<<"\t\tif(addparam#{index} &&"
			code<<"(((std::string)lhs->prints()).find(\"#{machine[:additionParam]}\")!=std::string::npos)"
			code<<"){\n"
			code<<"\t\t\tispara#{index} = true;\n"
			code<<"\t\t}\n"
		end
		code<<"\t\tif (ispara#{index}){\n" ##Add to paralist if this check is true
		#code<<"\tcount ++;\n"
		code<<"\t\t\tstd::list<Exp*>::iterator eit;\n"
		code<<"\t\t\teit=c->ABIparameters.begin();\n"
		code<<"\t\t\tc->ABIparameters.insert(eit,lhs);\n"
		code<<"\t\t}\n"## finish adding to paralist
		code<<"\t}\n"#END check each STMT
		
		code<<"\tbreak;}\n"##break after each type of machine
	end
	code<<"}\n" ##Finish machine architecture


	
	


	###FINISH WRITING CODE AND PUSH TO FILE
	@content = code
	write_to_output "test.cpp"
end
@content
def write_cpp_file 
	 mfile=""
	 indent = 0;
	File.open("procABI.m").each do |line|
		mfile<<line
		if line =~ /.*{.*/
			indent=indent+1
			#print line
		end
		if line =~ /.*}.*/
			indent=indent-1
		end
		if line =~ /\/\/##.+/
			indentstr="";
			print indent
			for temp in 1..indent
				indentstr<<"\t"
			end
			@content.each_line do |linecode|
				mfile<<indentstr
				mfile<<linecode	
			end
		end
	end
	@content=mfile
	write_to_output "test.cpp"
end

def write_to_output file
	File.open(file, "w") do |f|
		f.puts @content
	end
end

 spec = restructure_data
 code_generation spec
 write_cpp_file