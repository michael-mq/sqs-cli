require "aws-sdk"
require "inquirer"
require_relative "sqs"
require_relative "cli"

all_queue_urls = Cli.wait_with_message("Fetching queues...") do
  SQS.all_queues
end

source = Cli.list_or_file "Source", all_queue_urls,
  include_file: true

destination = Cli.list_or_file "Destination", all_queue_urls,
  include_file: !source[:filename]

delete_when_done = Ask.confirm "Delete message when processed?"


if source_url = source[:selected_item]
  count = 0
  SQS.read_message_batches(source_url) do |batch|

    batch.each do |m|
      count += 1
      print "."
    end

    if destination_url = destination[:selected_item]
      SQS.send_message_batches(destination_url, batch)
      SQS.delete_message_batches(source_url, batch) if delete_when_done
    end

  end
  puts "\nProcessed #{count} messages"
end
