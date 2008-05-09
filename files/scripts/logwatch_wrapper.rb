#!/usr/bin/ruby
require 'resolv'


class FilterEngine
	def filter(key,value)
		return send("filter_"+key.gsub(" ","_"),value)
	end


	def filter_kernel(value)
		result = nil
		value.each do |line|
			if ((line =~ /Logged [0-9]* packet[s]* on interface eth/).nil? &&
			   (line =~ /From [0-9]*.[0-9]*.[0-9]*.[0-9]* - [0-9]* packet[s]* to /).nil?)
				if result.nil?
					result = Array.new
				end
				result << line
			end
		end
		return result
	end

	def filter_dhcpd(value)
		result =  nil
		value.each do |line|
			if ((line =~ /Unknown Entries:/).nil? &&
		           (line =~ /DHCPOFFER on/).nil?)
				if result.nil?
					result = Array.new
				end
				result << line
			end
		end
		return result
	end

	def filter_named(value)
                result =  nil
                value.each do |line|
                        if ((line =~ /Unmatched Entries/).nil? &&
                           (line =~ /Starten von named succeeded:/).nil? &&
                           (line =~ /succeeded:/).nil?)
                                if result.nil?
                                        result = Array.new
                                end
                                result << line
                        end
                end
                return result
	end

	def filter_sendmail(value)
		result = nil
		value.each do |line|
			if ((line =~ /Bytes Transferred:/).nil? &&
			   (line =~ /Messages Sent:/).nil? &&
			   (line =~ /Unmatched Entries/).nil? &&
			   (line =~ /STARTTLS=client/).nil? &&
			   (line =~ /Top relays/).nil? &&
			   (line =~ /localhost.localdomain/).nil? &&
			   (line =~ /root@localhost/).nil? &&
			   (line =~ /apache@localhost/).nil? &&
			   (line =~ /sf@localhost/).nil? &&
			   (line =~ /vendredi.worldweb2000.com \[127.0.0.1\]/).nil? &&
			   (line =~ /messages returned after/).nil? &&
			   (line =~ /Warning!!!:/).nil? &&
			   (line =~ /Total recipients:/).nil?)
				if result.nil?
					result = Array.new
				end
				result << line	
			end
		end
		return result
	end

	def filter_mailscanner(value)
		#no logwatches from mailscanner
		return nil
	end

	def filter_init(value)
		result = nil
		value.each do |line|
			if (line =~ /Id \"x\" respawning too fast: disabled/).nil?
				if result.nil?
					result = Array.new
				end
				result << line
			end
		end
		return result
	end

	def method_missing( id, *args )
		if (args.length == 1)
			return args[0]
		else
			super id, args
		end
	end
end

class LogwatchWrapper
	$remote_logdir = '/var/log/remote'
	$doMail = false
	$mailAddress = 'monitor@worldweb2000.com'

	$filter_engine = FilterEngine.new
	
	# send email notification with error and info messages
	def send_notification(output)
	    email = "" \
	    << "From: monitor-sender@worldweb2000.com\n" \
	    << "To: #{$mailAddress}\n" \
	    << "Subject: Logwatch " + Time.now.to_s + "\n\n"
	
	    unless output.empty?
	      	output.each do |key,value|
			if !value.empty?
				email += filter_output(value)
			end
		end
	    end
	
	    File.popen("/usr/lib/sendmail -f monitor-sender@worldweb2000.com -t", "w") do |io|
	      io << email
	    end
	
	end
	
	def filter_output(output)
		result = ''
		topics = parse_output_into_topics(output)

		# > 1 because header is always set
		if (topics.size > 1) 
			topic_done = false
			result += ''.ljust(topics['header'][0].size,'#')+"\n"
			result += topics['header'][0]+"\n"
			result += ''.ljust(topics['header'][0].size,'#')+"\n\n"

			topics.each do |key,value|
				 temp_line = ''
				 filtered = $filter_engine.filter(key,value)
				 if !filtered.nil?
					 filtered.each do |line|
						temp_line += line
					 end
					 if (!temp_line.strip.empty? && key!='header')
						topic_done = true
						result += "\n---------------------------- "+key+" ----------------------------\n"
						result += temp_line
						result +=  "\n---------------------------- "+key+" end ----------------------------\n"
					 end
				 end
			end

			end_begin = '############################## Hosts end ' 
			result += end_begin+ ''.ljust(topics['header'][0].size-end_begin.size,'#')+"\n\n\n\n"
		end

		if topic_done 
			return result
		else
			return ''
		end
	end

	def parse_output_into_topics(output)
		result = Hash.new
		topic_entered = false
		topic = ''
		topic_end = ''
		i = 0
		output.each do |line|
			if (i==5)
				result['header'] = [ "#################### "+line.gsub(/^ */,'').gsub(/\n/,'')+" ####################" ]
			end	

			if ((i>6) &&
				!(line.include? "Logwatch End") &&
				!(line.strip.empty?)
				)
				if !topic_entered
					topic = line.gsub(/ -* (.*) Begin -* /,'\1')
					if topic != line
						topic = topic.downcase.gsub(/\n/,'')
						topic_entered = true				
					end
				else
					topic_end = line.gsub(/ -* (.*) End -* /,'\1')	
					if topic_end != line
						topic_entered = false
					else
						if result[topic].nil?
							result[topic] = Array.new
						end
						result[topic] << line
					end
				end
			end

			i = i.succ
		end
		return result
	end
	
	def parse 
		output = Hash.new
		
		d = Dir.new($remote_logdir)
		d.each  { |x|  
			if (x!='.')&&(x!='..')
		        	begin
			                hostname = Resolv.getname(x)
		        	rescue
		                	hostname = x
		        	end	
				options = ' --logdir '+$remote_logdir+'/'+x+' --hostname '+hostname + ' --print '	
				output[hostname] = Array.new
				IO.popen("logwatch "+options, "r") do |spopen|
					spopen.each_line do |line|
						output[hostname] << line
					end
				end
			end
		}
		return output
	end	
end

watcher = LogwatchWrapper.new
watcher.send_notification(watcher.parse)
