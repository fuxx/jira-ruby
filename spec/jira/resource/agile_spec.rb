require 'spec_helper'

describe JIRA::Resource::Agile do
  let(:client) do
    client = double(options: {rest_base_path: '/jira/rest/api/2', context_path: '/jira'})
    allow(client).to receive(:Issue).and_return(JIRA::Resource::IssueFactory.new(client))
    client
  end
  let(:response) { double }

  describe '#all' do
    it 'should query url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.all(client)
    end
  end

  describe '#get_backlog_issues' do
    it 'should query the url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/backlog?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_backlog_issues(client, 1)
    end
  end

  describe '#get_board_issues' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/issue?').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=id+IN%2810546%2C+10547%2C+10556%2C+10557%2C+10558%2C+10559%2C+10600%2C+10601%2C+10604%29').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      issues = JIRA::Resource::Agile.get_board_issues(client, 1)
      expect(issues).to be_an(Array)
      expect(issues.size).to eql(9)

      issues.each do |issue|
        expect(issue.class).to eq(JIRA::Resource::Issue)
        expect(issue.expanded?).to be_falsey
      end
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/issue?startAt=50').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=id+IN%2810546%2C+10547%2C+10556%2C+10557%2C+10558%2C+10559%2C+10600%2C+10601%2C+10604%29').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      issues = JIRA::Resource::Agile.get_board_issues(client, 1, startAt: 50)
      expect(issues).to be_an(Array)
      expect(issues.size).to eql(9)

      issues.each do |issue|
        expect(issue.class).to eq(JIRA::Resource::Issue)
        expect(issue.expanded?).to be_falsey
      end
    end

    context 'pagination' do
      it 'should allow to query less issues' do
        body = {
          "expand": "schema,names",
          "startAt": 0,
          "maxResults": 1000,
          "total": 9,
          "issues": [
            {
              "expand": "operations,versionedRepresentations,editmeta,changelog,renderedFields",
              "id": "10546",
              "self": "https://jira.example.com/rest/agile/1.0/issue/10546",
              "key": "SBT-1"
            },
            {
              "expand": "operations,versionedRepresentations,editmeta,changelog,renderedFields",
              "id": "10547",
              "self": "https://jira.example.com/rest/agile/1.0/issue/10547",
              "key": "SBT-2"
            },
            {
              "expand": "operations,versionedRepresentations,editmeta,changelog,renderedFields",
              "id": "10556",
              "self": "https://jira.example.com/rest/agile/1.0/issue/10556",
              "key": "SBT-11"
            }
          ]
        }.to_json

        expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/issue?maxResults=3').and_return(response)
        expect(response).to receive(:body).and_return(body)

        expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=id+IN%2810546%2C+10547%2C+10556%29&maxResults=3').and_return(response)
        expect(response).to receive(:body).and_return(body)

        issues = JIRA::Resource::Agile.get_board_issues(client, 1, maxResults: 3)
        expect(issues).to be_an(Array)
        expect(issues.size).to eql(3)
      end

      it 'should allow to query more issues' do
        nb_of_issues_to_test = 10

        body = {
          "expand": "schema,names",
          "startAt": 0,
          "maxResults": 1000,
          "total": 9,
          "issues":
          nb_of_issues_to_test.times.map do |i|
            {
              "expand": "operations,versionedRepresentations,editmeta,changelog,renderedFields",
              "id": (10000 + i).to_s,
              "self": "https://jira.example.com/rest/agile/1.0/issue/#{(10000 + i)}",
              "key": "SBT-#{i}"
            }
          end
        }.to_json

        expect(client).to receive(:get).with("/jira/rest/agile/1.0/board/1/issue?maxResults=#{nb_of_issues_to_test}").and_return(response)
        expect(response).to receive(:body).and_return(body)

        issue_ids = nb_of_issues_to_test.times.map { |i| 10000 + i }.join('%2C+')
        expect(client).to receive(:get).with("/jira/rest/api/2/search?jql=id+IN%28#{issue_ids}%29&maxResults=#{nb_of_issues_to_test}").and_return(response)
        expect(response).to receive(:body).and_return(body)

        issues = JIRA::Resource::Agile.get_board_issues(client, 1, maxResults: nb_of_issues_to_test)
        expect(issues).to be_an(Array)
        expect(issues.size).to eql(nb_of_issues_to_test)
      end
    end
  end

  describe '#get_sprints' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_sprints(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_sprints(client, 1, startAt: 50)
    end
  end

  describe '#get_sprint_issues' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      JIRA::Resource::Agile.get_sprint_issues(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      JIRA::Resource::Agile.get_sprint_issues(client, 1, startAt: 50)
    end
  end

  describe '#get_projects_full' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project/full').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects_full(client, 1)
    end
  end

  describe '#get_projects' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects(client, 1, startAt: 50)
    end
  end
end
