require "base64"
require 'octokit'
require 'securerandom'

githubToken = ENV['GITHUB_TOKEN']

reportDir = SecureRandom.uuid

client = Octokit::Client.new( :access_token => githubToken )

output = `git config --get remote.origin.url`

repo = output.strip.sub('git@github.com:', '').strip.sub('https://github.com/', '').sub('.git', '')

testReports = ""
cucumberReports = ""
coverageReports = ""
logsReports = ""
checkReports = ""

references = repo.split("/");

user = references[0]
repoName = references[1]

new_contents = Hash.new

t1 = Time.now
Dir.glob('**/build/reports/**/*').each do|f|
  if not File.directory?(f) then
    file = File.open(f, "r")
    content = file.read
    file.close

    new_contents[reportDir + "/" + f] =  Base64.encode64(content)

    if f.end_with? "index.html" then
        link = "https://" + user + ".github.io/" + repoName+ "/" + reportDir + "/" + f

        if f.include? "cucumber" then
            cucumberReports = cucumberReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
        elsif f.include? "jacoco" then
            coverageReports = coverageReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
        elsif f.include? "findBugs" then
            checkReports = checkReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
        elsif f.include? "findbugs" then
            checkReports = checkReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
        else
            testReports = testReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
        end
    end
  end
end

Dir.glob('**/*.log').each do|f|
  if not File.directory?(f) then
    file = File.open(f, "r")
    content = file.read
    file.close

    new_contents[reportDir + "/" + f] =  Base64.encode64(content)

    link = "https://" + user + ".github.io/" + repoName+ "/" + reportDir + "/" + f

    logsReports = logsReports + "<li>  " +  "<a href=\""+ link +"\">" + link + "</a></li>\n"
  end
end

new_tree = new_contents.map do |path, new_content|
  Hash(
    path: path,
    mode: "100644",
    type: "blob",
    sha: client.create_blob(repo, new_content, "base64")
  )
end

sha_latest_commit = client.ref(repo,"heads/gh-pages").object.sha

commit = client.git_commit(repo, sha_latest_commit)

tree = commit["tree"]

new_tree = client.create_tree(repo, new_tree, base_tree: tree["sha"])

commit_message = "Reports"
new_commit = client.create_commit(repo, commit_message, new_tree["sha"], commit["sha"])

client.update_ref(repo, "heads/gh-pages", new_commit["sha"])

t2 = Time.now

puts "it takes "  + (t2 - t1).to_s

pullMessage = "<html>\n" 

unless testReports.empty?
  pullMessage += "<details><summary><b> Test Reports </b></summary>\n" + testReports + "</details>\n" 
end

unless cucumberReports.empty?
  pullMessage += "<details><summary><b> Functional Test Reports </b></summary>\n" + cucumberReports + "</details>\n"
end

unless checkReports.empty?
  pullMessage += "<details><summary><b> Checks </b></summary>\n" + checkReports + "</details>\n" 
end

unless coverageReports.empty?
  pullMessage += "<details><summary><b> Coverage Reports </b></summary>\n" + coverageReports + "</details>\n"
end  

unless logsReports.empty?
  pullMessage += "<details><summary><b> Logs </b></summary>\n" + logsReports + "</details>\n" 
end

pullMessage += "</html>"

puts pullMessage

if not ENV['TRAVIS_PULL_REQUEST'].eql? "false"  then
	client.add_comment(repo, ENV['TRAVIS_PULL_REQUEST'], pullMessage)
end
