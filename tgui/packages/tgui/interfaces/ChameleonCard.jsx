import { useState } from 'react';
import {
  Button,
  Icon,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { AccessList } from './common/AccessList';

export const ChameleonCard = (props) => {
  const { act, data } = useBackend();

  const {
    accesses,
    selectedList,
    wildcardFlags,
    wildcardSlots,
    trimAccess,
    accessFlags,
    accessFlagNames,
    showBasic,
    ourAccess,
    theftAccess,
    ourTrimAccess,
    isCopying,
  } = data;

  const parsedAccess = accesses.flatMap((region) => {
    const regionName = region.name;
    const regionAccess = region.accesses;
    const parsedRegion = {
      name: regionName,
      accesses: [],
    };
    parsedRegion.accesses = regionAccess.filter((access) => {
      // Snip everything that's part of our trim.
      if (ourTrimAccess.includes(access.ref)) {
        return false;
      }
      // Add anything not part of our trim that's an access (assumed wildcard)
      // Also add any access on the ID card we're stealing from.
      if (ourAccess.includes(access.ref) || theftAccess.includes(access.ref)) {
        return true;
      }
      return false;
    });
    if (parsedRegion.accesses.length) {
      return parsedRegion;
    }
    return [];
  });

  return (
    <Window width={500} height={620}>
      <Window.Content scrollable>
        {isCopying ? (
          <AccessList
            accesses={parsedAccess}
            selectedList={selectedList}
            wildcardFlags={wildcardFlags}
            wildcardSlots={wildcardSlots}
            trimAccess={trimAccess}
            accessFlags={accessFlags}
            accessFlagNames={accessFlagNames}
            showBasic={!!showBasic}
            accessMod={(ref, wildcard) =>
              act('mod_access', {
                access_target: ref,
                access_wildcard: wildcard,
              })
            }
          />
        ) : (
          <AgentCard />
        )}
      </Window.Content>
    </Window>
  );
};

const AgentCard = (props) => {
  const [tabIndex, setTabIndex] = useState('tabIndex', 0);
  const decideTab = (index) => {
    switch (index) {
      case 0:
        return <AgentCardInfo />;
      case 1:
        return <AgentCardInfo />;
      // <AgentCardAppearances />;
      default:
        return <AgentCardInfo />;
    }
  };

  return (
    <Window width={425} height={500} theme="syndicate">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item textAlign="center">
            <Tabs fluid>
              <Tabs.Tab
                key="Card Info"
                selected={0 === tabIndex}
                onClick={() => setTabIndex(0)}
              >
                <Icon name="table" /> Card Info
              </Tabs.Tab>
              <Tabs.Tab
                key="Appearance"
                selected={1 === tabIndex}
                onClick={() => setTabIndex(1)}
              >
                <Icon name="id-card" /> Appearance
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          {decideTab(tabIndex)}
        </Stack>
      </Window.Content>
    </Window>
  );
};

export const AgentCardInfo = (props) => {
  const { act, data } = useBackend();
  const {
    registeredName,
    assignment,
    registered_age,
    registeredAccount,
    isWalletSpoofing,
  } = data;

  return (
    <>
      <Stack.Item>
        <Section title="Card Info">
          <LabeledList>
            <LabeledList.Item label="Name">
              <Button onClick={() => act('change_name')}>
                {registeredName || '[UNSET]'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Trim">
              <Button onClick={() => act('modify_trim')}>
                {'Modify Trim'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Occupation">
              <Button onClick={() => act('change_occupation')}>
                {assignment || '[UNSET]'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Age">
              <Button onClick={() => act('change_age')}>
                {registered_age || '[UNSET]'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Money Account">
              <Button onClick={() => act('change_money_account')}>
                {registeredAccount || '[UNSET]'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Wallet Spoofing">
              <Button onClick={() => act('change_wallet_spoofing')}>
                {isWalletSpoofing ? 'Spoofing' : 'Visible'}
              </Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill title="Card Settings">
          <LabeledList>
            <LabeledList.Item label="Card Info">
              <Button onClick={() => act('reset_card')}>Reset Card Info</Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
    </>
  );
};

/*
export const AgentCardAppearances = (props) => {
  const { act, data } = useBackend();
  const [selectedAppearance, setSelectedAppearance] = useState(
    'selectedAppearance'
  );
  const { appearances } = data;
  return (
    <Stack.Item grow>
      <Section fill scrollable title="Card Appearance">
        {appearances.map((appearance_unit) => (
          <Button
            compact
            m={0.5}
            color="translucent"
            key={appearance_unit.name}
            selected={appearance_unit === selectedAppearance}
          >
            <img
              src={`data:image/jped;base64,${appearance_unit.image}`}
              style={{
                width: '64px',
                'vertical-align': 'middle',
                '-ms-interpolation-mode': 'nearest-neighbor',
              }}
              onClick={() => {
                setSelectedAppearance(appearance_unit);
                act('change_appearance', {
                  new_appearance: appearance_unit.name,
                });
              }}
            />
          </Button>
        ))}
      </Section>
    </Stack.Item>
  );
};
*/
