#!/bin/bash

# Query jira for issues
# Params:
#       --key <jira ticket key>
#       --assignee <assignee>
#       --user-choice # if used, all information is provided to the user regardless of the ticket state, user is given a choice to confirm


#. ${HOME}/.jira-defines

echo "Go to lines with curl call first and insert your username and password. Then remove this line."; exit 1

function say
{
    echo "jira: $@"
}

function ask
{
    echo -n "jira: $@ "
}

jira_address="https://cs.diasemi.com/rest/api/2"

outputfile=$(mktemp jiraoutput.XXXXX)

key=
assignee=
userchoice="n"

while [ $# -gt 0 ]
do
    param=$1; shift
    case $param in
        "--key")
            key=$1; shift
        ;;
        "--assignee")
            assignee=$1; shift
        ;;
        "--user-choice")
            userchoice="y"
        ;;
    esac
done

say "Key=$key assignee=$assignee" >&2

if [[ "$userchoice" == "y" ]]
then
    say "User choice. You can override any result by confirming it."

    curl -D- -u 'vstepane:<password>' -X GET -H "Content-Type: application/json" "${jira_address}/search?jql=key=${key}&fields=id,key,assignee,summary" -o $outputfile &> /dev/null
    result=$(cat $outputfile | jq '.["total"]')
    if [[ "${result:0:1}" != "1" ]]
    then
        say "No issue of that key found."
    else
        assignee=$(cat $outputfile | jq '.issues[0].fields.assignee.name')
        summary=$(cat $outputfile | jq '.issues[0].fields.summary')

        say "Issue = $key"
        say "Assignee = $assignee"
        say "Summary = $summary"
    fi

    ask "Do you want to continue? [y/n]"
    read ans
    if [[ "$ans" == "y" ]]
    then
        say "User requests to continue."
        exit 0
    else
        say "Abandoning the commit."
        exit 1
    fi
fi


curl -D- -u 'vstepane:<password>' -X GET -H "Content-Type: application/json" "${jira_address}/search?jql=assignee=${assignee}+and+key=${key}&fields=id,key" -o $outputfile &> /dev/null

result=$(cat $outputfile | jq '.["total"]')
if [[ "${result:0:1}" != "1" ]]
then
    say "No issue with key '$key' found assigned to '$assignee'!"
    say "Check that the jira ticket key is correct."
    say "Check that the ticket is assigned to you."
    ask "Do you want to search for the ticket of key '$key' on all other assignees? [y/n]"
    read ans
    [[ "$ans" == "y" ]] && {
        curl -D- -u 'vstepane:<password>' -X GET -H "Content-Type: application/json" "${jira_address}/search?jql=key=${key}&fields=id,key,assignee,summary" -o $outputfile &> /dev/null
        result=$(cat $outputfile | jq '.["total"]')
        if [[ "${result:0:1}" == "1" ]]
        then
            assignee=$(cat $outputfile | jq '.issues[0].fields.assignee.name')
            summary=$(cat $outputfile | jq '.issues[0].fields.summary')
            say "Found assigned to: $assignee"
            say "The ticket's summary reads: '$summary'"
            ask "Is this really the ticket you want to commit under? [y/n]"
            read ans
            if [[ "$ans" == "y" ]]
            then
                say "Ticket validated."
                exit 0
            else
                say "Abandoning commit."
                exit 1
            fi
        else
            say "Not found. Seems like the given ticket doesn't exist."
            exit 1
        fi
    }
else
    say "Ticket validated."
    exit 0
fi

